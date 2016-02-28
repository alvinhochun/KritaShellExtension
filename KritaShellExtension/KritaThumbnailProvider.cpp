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

#include <zip.h>

#include <memory>
#include <new>

#include <gdiplus.h>
#include <shlwapi.h>

#pragma comment(lib, "gdiplus.lib")
#pragma comment(lib, "shlwapi.lib")

using namespace kritashellex;

namespace
{

class zip_deleter
{
public:
	void operator()(zip_source_t *p) const {
		zip_source_close(p);
	}

	void operator()(zip_t *p) const {
		zip_close(p);
	}

	void operator()(zip_file_t *p) const {
		zip_fclose(p);
	}
};

template<class T>
using zip_ptr = std::unique_ptr<T, zip_deleter>;

} // namespace

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
	return pStream->QueryInterface(&m_pStream);
}

IFACEMETHODIMP KritaThumbnailProvider::GetThumbnail(UINT cx, HBITMAP *phbmp, WTS_ALPHATYPE *pdwAlpha)
{
	if (!phbmp || !pdwAlpha) {
		return E_INVALIDARG;
	}

	HRESULT hr;

	*phbmp = nullptr;
	*pdwAlpha = WTSAT_ARGB;

	if (!m_pStream) {
		return E_UNEXPECTED;
	}

	HGLOBAL hImageContent;
	hr = getThumbnailPngFromArchive(m_pStream, cx, hImageContent);
	if (FAILED(hr)) {
		return hr;
	}

	IStream *pStream;
	hr = CreateStreamOnHGlobal(hImageContent, TRUE, &pStream);
	if (FAILED(hr)) {
		GlobalFree(hImageContent);
		return hr;
	}

	hr = getThumbnailFromPngStream(cx, pStream, *phbmp);
	if (FAILED(hr)) {
		return hr;
	}

	if (*phbmp) {
		return S_OK;
	}
	return E_FAIL;
}

HRESULT KritaThumbnailProvider::getThumbnailPngFromArchive(IStream *pStream, UINT cx, HGLOBAL &hImageContent_out)
{
	// TODO: Handle errors from libzip?

	zip_ptr<zip_source_t> src(zip_source_IStream_create(pStream, nullptr));
	if (!src) {
		return E_NOTIMPL;
	}
	zip_ptr<zip_t> zf(zip_open_from_source(src.get(), ZIP_RDONLY, nullptr));
	if (!zf) {
		return E_NOTIMPL;
	}

	const char *szImageFileName = "preview.png";
	if (cx > 256) {
		szImageFileName = "mergedimage.png";
	}
	zip_stat_t fstat;
	if (zip_stat(zf.get(), szImageFileName, ZIP_FL_UNCHANGED, &fstat) != 0) {
		return E_NOTIMPL;
	}

	zip_ptr<zip_file_t> file(zip_fopen(zf.get(), szImageFileName, ZIP_FL_UNCHANGED));
	if (!file) {
		return E_NOTIMPL;
	}

	unsigned long long imageSize64 = fstat.size;
	unsigned long imageSize = static_cast<unsigned long>(imageSize64);
	if (imageSize != imageSize64) {
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

	int read = static_cast<int>(zip_fread(file.get(), pImageContent, imageSize));
	if (read != imageSize) {
		GlobalUnlock(hImageContent_out);
		GlobalFree(hImageContent_out);
		return E_NOTIMPL;
	}

	GlobalUnlock(hImageContent_out);
	return S_OK;
}

HRESULT KritaThumbnailProvider::getThumbnailFromPngStream(UINT cx, IStream *pStream, HBITMAP &hbmp_out)
{
	ULONG_PTR token;
	Gdiplus::GdiplusStartupInput input;
	if (Gdiplus::GdiplusStartup(&token, &input, nullptr) != Gdiplus::Ok) {
		pStream->Release();
		return E_FAIL;
	}

	HRESULT hr = getThumbnailFromPngStreamGdiplus(cx, pStream, hbmp_out);

	Gdiplus::GdiplusShutdown(token);

	if (FAILED(hr)) {
		return hr;
	}
	return S_OK;
}

HRESULT KritaThumbnailProvider::getThumbnailFromPngStreamGdiplus(UINT cx, IStream *pStream, HBITMAP &hbmp_out)
{
	std::unique_ptr<Gdiplus::Bitmap> pImageBitmap(new Gdiplus::Bitmap(pStream));
	pStream->Release();
	if (pImageBitmap->GetLastStatus() != Gdiplus::Ok) {
		return E_FAIL;
	}

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
		g.DrawImage(pImageBitmap.get(), 0, 0, dstWidth, dstHeight);
	}
	pDstBitmap->GetHBITMAP(Gdiplus::Color::Transparent, &hbmp_out);

	return S_OK;
}
