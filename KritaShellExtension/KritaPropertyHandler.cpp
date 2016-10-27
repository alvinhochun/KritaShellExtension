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
#include "document.h"

#include <zip.h>

#include <memory>
#include <new>

#include <propkey.h>
#include <propvarutil.h>
#include <shlwapi.h>
#include <strsafe.h>

#pragma comment(lib, "propsys.lib")

using namespace kritashellex;

KritaPropertyHandler::KritaPropertyHandler() :
	m_refCount(1),
	m_pStream(nullptr),
	m_pDocument(nullptr),
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
#pragma warning(push)
#pragma warning(disable: 4838)
	};
#pragma warning(pop)
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

	// TODO: Handle errors from libzip?

	zip_ptr<zip_source_t> src(zip_source_IStream_create(m_pStream, nullptr));
	if (!src) {
		return E_NOTIMPL;
	}
	zip_error_t zip_error;
	zip_ptr<zip_t> zf(zip_open_from_source(src.get(), ZIP_CHECKCONS | ZIP_RDONLY, &zip_error));
	if (!zf) {
		return E_NOTIMPL;
	}
	std::unique_ptr<Document> pDocument(new (std::nothrow) Document(std::move(zf), std::move(src)));
	if (!pDocument->Init()) {
		return E_NOTIMPL;
	}
	m_pDocument = std::move(pDocument);

	hr = loadProperties();
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

HRESULT KritaPropertyHandler::loadProperties()
{
	// TODO: Handle uninitialized properties properly

	static_assert(UINT_MAX <= 9999999999, "unsigned int is somehow no longer 10-char max");
	WCHAR wszDimensions[24]; // 2x 10-char-max int, 3x char, 1x null

	HRESULT hr = StringCbPrintfW(wszDimensions, sizeof(wszDimensions), L"%u x %u", m_pDocument->getWidth(), m_pDocument->getHeight());
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
	hr = InitPropVariantFromUInt32(m_pDocument->getWidth(), &propHSize);
	if (FAILED(hr)) {
		return hr;
	}
	PROPVARIANT propVSize;
	PropVariantInit(&propVSize);
	hr = InitPropVariantFromUInt32(m_pDocument->getHeight(), &propVSize);
	if (FAILED(hr)) {
		return hr;
	}
	PROPVARIANT propHRes;
	PropVariantInit(&propHRes);
	hr = InitPropVariantFromDouble(m_pDocument->getXRes(), &propHRes);
	if (FAILED(hr)) {
		return hr;
	}
	PROPVARIANT propVRes;
	PropVariantInit(&propVRes);
	hr = InitPropVariantFromDouble(m_pDocument->getYRes(), &propVRes);
	if (FAILED(hr)) {
		return hr;
	}

	hr = m_pCache->SetValueAndState(PKEY_Image_Dimensions, &propDimensions, PSC_NORMAL);
	if (FAILED(hr)) {
		PropVariantClear(&propDimensions);
		PropVariantClear(&propHSize);
		PropVariantClear(&propVSize);
		PropVariantClear(&propHRes);
		PropVariantClear(&propVRes);
		return hr;
	}
	hr = m_pCache->SetValueAndState(PKEY_Image_HorizontalSize, &propHSize, PSC_NORMAL);
	if (FAILED(hr)) {
		PropVariantClear(&propHSize);
		PropVariantClear(&propVSize);
		PropVariantClear(&propHRes);
		PropVariantClear(&propVRes);
		return hr;
	}
	hr = m_pCache->SetValueAndState(PKEY_Image_VerticalSize, &propVSize, PSC_NORMAL);
	if (FAILED(hr)) {
		PropVariantClear(&propVSize);
		PropVariantClear(&propHRes);
		PropVariantClear(&propVRes);
		return hr;
	}
	hr = m_pCache->SetValueAndState(PKEY_Image_HorizontalResolution, &propHRes, PSC_NORMAL);
	if (FAILED(hr)) {
		PropVariantClear(&propHRes);
		PropVariantClear(&propVRes);
		return hr;
	}
	hr = m_pCache->SetValueAndState(PKEY_Image_VerticalResolution, &propVRes, PSC_NORMAL);
	if (FAILED(hr)) {
		PropVariantClear(&propVRes);
		return hr;
	}

	return S_OK;
}
