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

#include <algorithm>
#include <memory>
#include <new>

#include <gdiplus.h>
#include <shlwapi.h>

// Kill the evilness
#undef min
#undef max

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
#pragma warning(push)
#pragma warning(disable: 4838)
	};
#pragma warning(pop)
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

	// HACK: Work around small previews being larger than actual image
	if (cx <= 256 && (m_pDocument->getWidth() < 256 && m_pDocument->getHeight() < 256)) {
		cx = std::min(std::max(m_pDocument->getWidth(), m_pDocument->getHeight()), cx);
	}

	ULONG_PTR token;
	Gdiplus::GdiplusStartupInput input;
	if (Gdiplus::GdiplusStartup(&token, &input, nullptr) != Gdiplus::Ok) {
		return E_FAIL;
	}

	{
		std::unique_ptr<Gdiplus::Bitmap> pImageBitmap;
		hr = getBitmapFromArchiveForThumbnail(cx, pImageBitmap);
		if (FAILED(hr)) {
			Gdiplus::GdiplusShutdown(token);
			return hr;
		}

		hr = getThumbnailFromBitmap(cx, pImageBitmap.get(), *phbmp);
	}

	Gdiplus::GdiplusShutdown(token);

	if (FAILED(hr)) {
		return hr;
	}

	if (*phbmp) {
		return S_OK;
	}
	return E_FAIL;
}

HRESULT KritaThumbnailProvider::getBitmapFromArchiveForThumbnail(UINT cx, std::unique_ptr<Gdiplus::Bitmap> &pImageBitmap_out) const
{
	HRESULT hr;

	// Try mergedimage.png if requested size is larger than 256px,
	// or if image is below 256px so it won't get all blurry
	if (cx > 256 || (cx <= 256 && (m_pDocument->getWidth() < 256 && m_pDocument->getHeight() < 256))) {
		hr = getBitmapFromArchiveByName("mergedimage.png", pImageBitmap_out);
		if (SUCCEEDED(hr)) {
			return S_OK;
		}
	}

	switch (m_pDocument->getFileType()) {
	case Document::FILETYPE_KRA:
		hr = getBitmapFromArchiveByName("preview.png", pImageBitmap_out); 
		break;
	case Document::FILETYPE_ORA:
		hr = getBitmapFromArchiveByName("Thumbnails/thumbnail.png", pImageBitmap_out); 
		break;
	default:
		hr = E_NOTIMPL;
	}

	if (SUCCEEDED(hr)) {
		// Check thumbnail size and aspect ratio
		// Give a +-1px tolerance when checking the scaled side
		unsigned long imageHeight = m_pDocument->getHeight();
		unsigned long imageWidth = m_pDocument->getWidth();
		unsigned long thumbHeight = pImageBitmap_out->GetHeight();
		unsigned long thumbWidth = pImageBitmap_out->GetWidth();
		if (imageHeight == imageWidth) {
			if (thumbWidth == 256 && thumbHeight == 256) {
				return S_OK;
			}
		} else if (imageHeight > imageWidth) {
			if (thumbHeight == 256) {
				unsigned long scaledWidth = std::max(256 * imageWidth / imageHeight, 1ul);
				if (thumbWidth <= scaledWidth + 1 && thumbWidth >= scaledWidth - 1) {
					return S_OK;
				}
			}
		} else {
			if (thumbWidth == 256) {
				unsigned long scaledHeight = std::max(256 * imageHeight / imageWidth, 1ul);
				if (thumbHeight <= scaledHeight + 1 && thumbHeight >= scaledHeight - 1) {
					return S_OK;
				}
			}
		}
	}

	// Try mergedimage.png if thumbnail can't be used
	hr = getBitmapFromArchiveByName("mergedimage.png", pImageBitmap_out);
	if (SUCCEEDED(hr)) {
		return S_OK;
	}

	return hr;
}

HRESULT KritaThumbnailProvider::getBitmapFromArchiveByName(const char *const filename, std::unique_ptr<Gdiplus::Bitmap> &pImageBitmap_out) const
{
	HRESULT hr;

	HGLOBAL hImageContent;
	hr = getThumbnailPngFromArchiveByName(filename, hImageContent);
	if (FAILED(hr)) {
		return hr;
	}

	IStream *pStream;
	hr = CreateStreamOnHGlobal(hImageContent, TRUE, &pStream);
	if (FAILED(hr)) {
		GlobalFree(hImageContent);
		return hr;
	}

	std::unique_ptr<Gdiplus::Bitmap> pImageBitmap;
	hr = getBitmapFromPngStreamGdiplus(pStream, pImageBitmap);
	if (FAILED(hr)) {
		return hr;
	}
	pImageBitmap_out = std::move(pImageBitmap);

	return S_OK;
}

HRESULT KritaThumbnailProvider::getThumbnailPngFromArchiveByName(const char *const filename, HGLOBAL &hImageContent_out) const
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
