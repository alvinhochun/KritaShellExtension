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

#pragma once

#include <zip.h>

#include <memory>

#include <windows.h>
#include <thumbcache.h>

namespace kritashellex
{

class Document;

class KritaThumbnailProvider :
	public IThumbnailProvider,
	public IInitializeWithStream
{
private:
	unsigned long m_refCount;
	IStream *m_pStream;
	std::unique_ptr<Document> m_pDocument;

public:
	KritaThumbnailProvider();

	// Implements IUnknown

	IFACEMETHODIMP QueryInterface(REFIID riid, void **ppv) override;
	IFACEMETHODIMP_(ULONG) AddRef() override;
	IFACEMETHODIMP_(ULONG) Release() override;

	// Implements IInitializeWithStream

	IFACEMETHODIMP Initialize(IStream *pStream, DWORD grfMode) override;

	// Implements IThumbnailProvider

	IFACEMETHODIMP GetThumbnail(UINT cx, HBITMAP *phbmp, WTS_ALPHATYPE *pdwAlpha) override;

protected:
	~KritaThumbnailProvider();

private:
	HRESULT getThumbnailPngFromArchive(UINT cx, HGLOBAL &hImageContent_out);
	HRESULT getThumbnailPngFromArchiveByName(UINT cx, const char *const filename, HGLOBAL &hImageContent_out);
	static HRESULT getThumbnailFromPngStream(UINT cx, IStream *pStream, HBITMAP &hbmp_out);
	static HRESULT getThumbnailFromPngStreamGdiplus(UINT cx, IStream *pStream, HBITMAP &hbmp_out);
};

} // namespace kritashellex
