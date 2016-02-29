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
#include "KritaPropertyHandler.h"
#include "zip_source_IStream.h"

#include <zip.h>
#include <tinyxml2.h>

#include <memory>
#include <new>

#include <propkey.h>
#include <propvarutil.h>
#include <shlwapi.h>
#include <strsafe.h>

#pragma comment(lib, "propsys.lib")

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

KritaPropertyHandler::KritaPropertyHandler() :
	m_refCount(1),
	m_pStream(nullptr),
	m_pCache(nullptr)
{
	IncDllRef();
}

KritaPropertyHandler::~KritaPropertyHandler()
{
	DecDllRef();
}

IFACEMETHODIMP KritaPropertyHandler::QueryInterface(REFIID riid, void **ppv)
{
	static const QITAB qit[] = {
		QITABENT(KritaPropertyHandler, IPropertyStore),
		QITABENT(KritaPropertyHandler, IInitializeWithStream),
		{ nullptr },
	};
	return QISearch(this, qit, riid, ppv);
}

IFACEMETHODIMP_(ULONG) KritaPropertyHandler::AddRef()
{
	return InterlockedIncrement(&m_refCount);
}

IFACEMETHODIMP_(ULONG) KritaPropertyHandler::Release()
{
	unsigned long refCount = InterlockedDecrement(&m_refCount);
	if (refCount == 0) {
		if (m_pStream) {
			m_pStream->Release();
		}
		if (m_pCache) {
			m_pCache->Release();
		}
		delete this;
	}
	return refCount;
}

IFACEMETHODIMP KritaPropertyHandler::Initialize(IStream *pStream_, DWORD grfMode)
{
	if (m_pStream) {
		return HRESULT_FROM_WIN32(ERROR_ALREADY_INITIALIZED);
	}

	HRESULT hr = pStream_->QueryInterface(&m_pStream);
	if (FAILED(hr)) {
		return hr;
	}

	hr = PSCreateMemoryPropertyStore(IID_PPV_ARGS(&m_pCache));
	if (FAILED(hr)) {
		return hr;
	}

	// TODO: Create XML object?

	std::unique_ptr<char[]> pMaindocContent;
	unsigned long maindocLength;
	hr = getMaindocFromArchive(m_pStream, pMaindocContent, maindocLength);
	if (FAILED(hr)) {
		return hr;
	}

	hr = parseMaindocXml(std::move(pMaindocContent), maindocLength, m_pCache);
	if (FAILED(hr)) {
		return hr;
	}

	return S_OK;
}

IFACEMETHODIMP KritaPropertyHandler::GetCount(DWORD *pcProps)
{
	if (!pcProps) {
		return E_INVALIDARG;
	}

	*pcProps = 0;

	if (!m_pCache) {
		return E_UNEXPECTED;
	}

	return m_pCache->GetCount(pcProps);
}

IFACEMETHODIMP KritaPropertyHandler::GetAt(DWORD iProp, PROPERTYKEY *pkey)
{
	if (!pkey) {
		return E_INVALIDARG;
	}

	*pkey = PKEY_Null;

	if (!m_pCache) {
		return E_UNEXPECTED;
	}

	return m_pCache->GetAt(iProp, pkey);
}

IFACEMETHODIMP KritaPropertyHandler::GetValue(const PROPERTYKEY &key, PROPVARIANT *pPropVar)
{
	if (!pPropVar) {
		return E_INVALIDARG;
	}

	PropVariantInit(pPropVar);

	if (!m_pCache) {
		return E_UNEXPECTED;
	}

	return m_pCache->GetValue(key, pPropVar);
}

IFACEMETHODIMP KritaPropertyHandler::SetValue(const PROPERTYKEY &key, const PROPVARIANT &propVar)
{
	// All properties are read-only.
	// According to MSDN, STG_E_INVALIDARG should be returned,
	// but that doesn't exist, so we'll take this one.
	return STG_E_INVALIDPARAMETER;
}

IFACEMETHODIMP KritaPropertyHandler::Commit()
{
	// All properties are read-only.
	// According to MSDN, STG_E_INVALIDARG should be returned,
	// but that doesn't exist, so we'll take this one.
	return STG_E_INVALIDPARAMETER;
}

HRESULT KritaPropertyHandler::getMaindocFromArchive(IStream *pStream, std::unique_ptr<char[]> &pMaindocContent_out, unsigned long &len_out)
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

	const char *szImageFileName = "maindoc.xml";
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

	std::unique_ptr<char[]> pMaindocContent(new (std::nothrow) char[imageSize]);
	if (!pMaindocContent) {
		return E_OUTOFMEMORY;
	}

	int read = static_cast<int>(zip_fread(file.get(), pMaindocContent.get(), imageSize));
	if (read != imageSize) {
		return E_NOTIMPL;
	}

	pMaindocContent_out = std::move(pMaindocContent);
	len_out = imageSize;

	return S_OK;
}

HRESULT KritaPropertyHandler::parseMaindocXml(std::unique_ptr<char[]> &&pMaindoc, unsigned long len, IPropertyStoreCache *pCache)
{
	tinyxml2::XMLDocument xmlDoc;
	tinyxml2::XMLError err;
	// tinyxml2 doesn't use std::nothrow in XMLDocument::Parse, so we'd catch the exception.
	try {
		err = xmlDoc.Parse(pMaindoc.get(), len);
	}
	catch (std::bad_alloc) {
		return E_OUTOFMEMORY;
	}
	if (err != tinyxml2::XML_NO_ERROR) {
		return E_NOTIMPL;
	}

	// XMLDocument::Parse copies to an internal buffer so we can free the buffer already.
	pMaindoc.reset(nullptr);

	const tinyxml2::XMLElement *elemDoc = xmlDoc.FirstChildElement("DOC");
	if (!elemDoc) {
		return E_NOTIMPL;
	}

	const tinyxml2::XMLElement *elemImage = elemDoc->FirstChildElement("IMAGE");
	if (!elemImage) {
		return E_NOTIMPL;
	}

	kritafileprops props;

	err = elemImage->QueryUnsignedAttribute("width", &props.width);
	if (err != tinyxml2::XML_NO_ERROR) {
		return E_NOTIMPL;
	}

	err = elemImage->QueryUnsignedAttribute("height", &props.height);
	if (err != tinyxml2::XML_NO_ERROR) {
		return E_NOTIMPL;
	}

	err = elemImage->QueryDoubleAttribute("x-res", &props.xRes);
	if (err != tinyxml2::XML_NO_ERROR) {
		return E_NOTIMPL;
	}

	err = elemImage->QueryDoubleAttribute("y-res", &props.yRes);
	if (err != tinyxml2::XML_NO_ERROR) {
		return E_NOTIMPL;
	}

	static_assert(UINT_MAX <= 999999999, "unsigned int is somehow no longer 10-char max");
	WCHAR wszDimensions[24]; // 2x 10-char-max int, 3x char, 1x null

	HRESULT hr = StringCbPrintfW(wszDimensions, sizeof(wszDimensions), L"%u x %u", props.width, props.height);
	if (FAILED(hr)) {
		return hr;
	}

	PROPVARIANT propDimensions;
	PropVariantInit(&propDimensions);
	hr = InitPropVariantFromString(wszDimensions, &propDimensions);
	if (FAILED(hr)) {
		return hr;
	}
	PROPVARIANT propHSize;
	PropVariantInit(&propHSize);
	hr = InitPropVariantFromUInt32(props.width, &propHSize);
	if (FAILED(hr)) {
		return hr;
	}
	PROPVARIANT propVSize;
	PropVariantInit(&propVSize);
	hr = InitPropVariantFromUInt32(props.height, &propVSize);
	if (FAILED(hr)) {
		return hr;
	}
	PROPVARIANT propHRes;
	PropVariantInit(&propHRes);
	hr = InitPropVariantFromDouble(props.xRes, &propHRes);
	if (FAILED(hr)) {
		return hr;
	}
	PROPVARIANT propVRes;
	PropVariantInit(&propVRes);
	hr = InitPropVariantFromDouble(props.yRes, &propVRes);
	if (FAILED(hr)) {
		return hr;
	}

	hr = pCache->SetValueAndState(PKEY_Image_Dimensions, &propDimensions, PSC_NORMAL);
	if (FAILED(hr)) {
		PropVariantClear(&propDimensions);
		PropVariantClear(&propHSize);
		PropVariantClear(&propVSize);
		PropVariantClear(&propHRes);
		PropVariantClear(&propVRes);
		return hr;
	}
	hr = pCache->SetValueAndState(PKEY_Image_HorizontalSize, &propHSize, PSC_NORMAL);
	if (FAILED(hr)) {
		PropVariantClear(&propHSize);
		PropVariantClear(&propVSize);
		PropVariantClear(&propHRes);
		PropVariantClear(&propVRes);
		return hr;
	}
	hr = pCache->SetValueAndState(PKEY_Image_VerticalSize, &propVSize, PSC_NORMAL);
	if (FAILED(hr)) {
		PropVariantClear(&propVSize);
		PropVariantClear(&propHRes);
		PropVariantClear(&propVRes);
		return hr;
	}
	hr = pCache->SetValueAndState(PKEY_Image_HorizontalResolution, &propHRes, PSC_NORMAL);
	if (FAILED(hr)) {
		PropVariantClear(&propHRes);
		PropVariantClear(&propVRes);
		return hr;
	}
	hr = pCache->SetValueAndState(PKEY_Image_VerticalResolution, &propVRes, PSC_NORMAL);
	if (FAILED(hr)) {
		PropVariantClear(&propVRes);
		return hr;
	}

	return S_OK;
}
