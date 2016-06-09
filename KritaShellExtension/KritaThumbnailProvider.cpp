/*
 * Copyright (c) 2016 Alvin Wong <alvinhochun@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#include "dllmain.h"
#include "KritaThumbnailProvider.h"
#include "zip_source_IStream.h"
#include "document.h"

#include <zip.h>

#include <memory>
#include <new>

#include <gdiplus.h>
#include <shlwapi.h>

#pragma comment(lib, "gdiplus.lib")
#pragma comment(lib, "shlwapi.lib")

using namespace kritashellex;

KritaThumbnailProvider::KritaThumbnailProvider() :
	m_refCount(1),
	m_pStream(nullptr)
{
	IncDllRef();
}

KritaThumbnailProvider::~KritaThumbnailProvider()
{
	DecDllRef();
}

IFACEMETHODIMP KritaThumbnailProvider::QueryInterface(REFIID riid, void **ppv)
{
	static const QITAB qit[] = {
		QITABENT(KritaThumbnailProvider, IThumbnailProvider),
		QITABENT(KritaThumbnailProvider, IInitializeWithStream),
		{ nullptr },
	};
	return QISearch(this, qit, riid, ppv);
}

IFACEMETHODIMP_(ULONG) KritaThumbnailProvider::AddRef()
{
	return InterlockedIncrement(&m_refCount);
}

IFACEMETHODIMP_(ULONG) KritaThumbnailProvider::Release()
{
	unsigned long refCount = InterlockedDecrement(&m_refCount);
	if (refCount == 0) {
		if (m_pStream) {
			m_pStream->Release();
		}
		delete this;
	}
	return refCount;
}

IFACEMETHODIMP KritaThumbnailProvider::Initialize(IStream *pStream, DWORD grfMode)
{
	if (m_pStream) {
		return HRESULT_FROM_WIN32(ERROR_ALREADY_INITIALIZED);
	}

	HRESULT hr = pStream->QueryInterface(&m_pStream);
	if (FAILED(hr)) {
		return hr;
	}

	// TODO: Handle errors from libzip?

	zip_ptr<zip_source_t> src(zip_source_IStream_create(pStream, nullptr));
	if (!src) {
		return E_NOTIMPL;
	}
	zip_ptr<zip_t> zf(zip_open_from_source(src.get(), ZIP_RDONLY, nullptr));
	if (!zf) {
		return E_NOTIMPL;
	}
	std::unique_ptr<Document> pDocument(new (std::nothrow) Document(std::move(zf), std::move(src)));
	if (!pDocument->Init()) {
		return E_NOTIMPL;
	}
	m_pDocument = std::move(pDocument);

	return S_OK;
}

IFACEMETHODIMP KritaThumbnailProvider::GetThumbnail(UINT cx, HBITMAP *phbmp, WTS_ALPHATYPE *pdwAlpha)
{
	if (!phbmp || !pdwAlpha) {
		return E_INVALIDARG;
	}

	HRESULT hr;

	*phbmp = nullptr;
	*pdwAlpha = WTSAT_ARGB;

	if (!m_pDocument) {
		return E_UNEXPECTED;
	}

	HGLOBAL hImageContent;
	hr = getThumbnailPngFromArchive(cx, hImageContent);
	if (FAILED(hr)) {
		return hr;
	}

	IStream *pStream;
	hr = CreateStreamOnHGlobal(hImageContent, TRUE, &pStream);
	if (FAILED(hr)) {
		GlobalFree(hImageContent);
		return hr;
	}

	ULONG_PTR token;
	Gdiplus::GdiplusStartupInput input;
	if (Gdiplus::GdiplusStartup(&token, &input, nullptr) != Gdiplus::Ok) {
		pStream->Release();
		return E_FAIL;
	}

	hr = getThumbnailFromPngStreamGdiplus(cx, pStream, *phbmp);

	Gdiplus::GdiplusShutdown(token);

	if (FAILED(hr)) {
		return hr;
	}

	if (*phbmp) {
		return S_OK;
	}
	return E_FAIL;
}

HRESULT KritaThumbnailProvider::getThumbnailPngFromArchive(UINT cx, HGLOBAL &hImageContent_out) const
{
	const char *szImageFileName = nullptr;
	if (cx > 256) {
		szImageFileName = "mergedimage.png";
	}

	if (!szImageFileName || FAILED(getThumbnailPngFromArchiveByName(cx, szImageFileName, hImageContent_out))) {
		// Try preview.png for .kra files
		szImageFileName = "preview.png";
		if (FAILED(getThumbnailPngFromArchiveByName(cx, szImageFileName, hImageContent_out))) {
			// Try Thumbnails/thumbnail.png for .ora files
			szImageFileName = "Thumbnails/thumbnail.png";
			if (FAILED(getThumbnailPngFromArchiveByName(cx, szImageFileName, hImageContent_out))) {
				if (cx > 256) {
					return E_NOTIMPL;
				} else {
					// Try mergedimage.png if thumbnail can't be used
					szImageFileName = "mergedimage.png";
					if (FAILED(getThumbnailPngFromArchiveByName(cx, szImageFileName, hImageContent_out))) {
						return E_NOTIMPL;
					}
				}
			}
		}
	}

	return S_OK;
}

HRESULT KritaThumbnailProvider::getThumbnailPngFromArchiveByName(UINT cx, const char *const filename, HGLOBAL &hImageContent_out) const
{
	size_t imageSize;
	if (!m_pDocument->getFileSize(filename, imageSize)) {
		return E_NOTIMPL;
	}

	hImageContent_out = GlobalAlloc(GMEM_MOVEABLE, imageSize);
	if (!hImageContent_out) {
		return HRESULT_FROM_WIN32(GetLastError());
	}
	LPVOID pImageContent = GlobalLock(hImageContent_out);
	if (!pImageContent) {
		GlobalFree(hImageContent_out);
		return HRESULT_FROM_WIN32(GetLastError());
	}

	if (!m_pDocument->getFileContent(filename, static_cast<char *>(pImageContent), imageSize)) {
		GlobalUnlock(hImageContent_out);
		GlobalFree(hImageContent_out);
		return E_NOTIMPL;
	}

	GlobalUnlock(hImageContent_out);
	return S_OK;
}

HRESULT KritaThumbnailProvider::getThumbnailFromPngStreamGdiplus(UINT cx, IStream *pStream, HBITMAP &hbmp_out)
{
	std::unique_ptr<Gdiplus::Bitmap> pImageBitmap;
	HRESULT hr = getBitmapFromPngStreamGdiplus(pStream, pImageBitmap);
	if (FAILED(hr)) {
		return hr;
	}

	hr = getThumbnailFromBitmap(cx, pImageBitmap.get(), hbmp_out);

	if (FAILED(hr)) {
		return hr;
	}
	return S_OK;
}

HRESULT KritaThumbnailProvider::getBitmapFromPngStreamGdiplus(IStream *pStream, std::unique_ptr<Gdiplus::Bitmap> &pImageBitmap_out)
{
	std::unique_ptr<Gdiplus::Bitmap> pImageBitmap(new Gdiplus::Bitmap(pStream));
	pStream->Release();
	if (pImageBitmap->GetLastStatus() != Gdiplus::Ok) {
		return E_FAIL;
	}
	pImageBitmap_out = std::move(pImageBitmap);

	return S_OK;
}

HRESULT KritaThumbnailProvider::getThumbnailFromBitmap(UINT cx, Gdiplus::Bitmap *pImageBitmap, HBITMAP &hbmp_out)
{
	unsigned long imageHeight = pImageBitmap->GetHeight();
	unsigned long imageWidth = pImageBitmap->GetWidth();
	unsigned long dstHeight, dstWidth;
	if (imageHeight <= cx && imageWidth <= cx) {
		// If image fits into or is smaller than requested size, don't scale at all
		dstWidth = imageWidth;
		dstHeight = imageHeight;
	} else if (imageHeight == imageWidth) {
		dstWidth = cx;
		dstHeight = cx;
	} else if (imageHeight > imageWidth) {
		dstWidth = cx * imageWidth / imageHeight;
		dstHeight = cx;
	} else {
		dstWidth = cx;
		dstHeight = cx * imageHeight / imageWidth;
	}

	std::unique_ptr<Gdiplus::Bitmap> pDstBitmap(new Gdiplus::Bitmap(dstWidth, dstHeight, PixelFormat32bppARGB));
	if (pDstBitmap->GetLastStatus() != Gdiplus::Ok) {
		return E_FAIL;
	}
	{
		Gdiplus::Graphics g(pDstBitmap.get());
		g.DrawImage(pImageBitmap, 0, 0, dstWidth, dstHeight);
	}
	pDstBitmap->GetHBITMAP(Gdiplus::Color::Transparent, &hbmp_out);

	return S_OK;
}
