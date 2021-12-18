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
#include "KritaPropertyHandler.h"
#include "ClassFactory.h"

#include <new>

#include <shlwapi.h>

#pragma comment(lib, "shlwapi.lib")

using namespace kritashellex;

ClassFactory::ClassFactory(Type type) :
	m_type(type),
	m_refCount(1)
{
	IncDllRef();
}

ClassFactory::~ClassFactory()
{
	DecDllRef();
}

IFACEMETHODIMP ClassFactory::QueryInterface(REFIID riid, void **ppv)
{
	static const QITAB qit[] = {
		QITABENT(ClassFactory, IClassFactory),
		{ nullptr },
#pragma warning(push)
#pragma warning(disable: 4838)
	};
#pragma warning(pop)
	return QISearch(this, qit, riid, ppv);
}

IFACEMETHODIMP_(ULONG) ClassFactory::AddRef()
{
	return InterlockedIncrement(&m_refCount);
}

IFACEMETHODIMP_(ULONG) ClassFactory::Release()
{
	unsigned long refCount = InterlockedDecrement(&m_refCount);
	if (refCount == 0) {
		delete this;
	}
	return refCount;
}

IFACEMETHODIMP ClassFactory::CreateInstance(IUnknown *pUnkOuter, REFIID riid, void **ppv)
{
	if (pUnkOuter) {
		return CLASS_E_NOAGGREGATION;
	}
	switch (m_type) {
	case CLASS_THUMBNAIL:
	{
		KritaThumbnailProvider *pExt = new (std::nothrow) KritaThumbnailProvider();
		if (!pExt) {
			return E_OUTOFMEMORY;
		}
		HRESULT hr = pExt->QueryInterface(riid, ppv);
		pExt->Release();
		return hr;
	}
	case CLASS_PROPERTY:
	{
		KritaPropertyHandler *pExt = new (std::nothrow) KritaPropertyHandler();
		if (!pExt) {
			return E_OUTOFMEMORY;
		}
		HRESULT hr = pExt->QueryInterface(riid, ppv);
		pExt->Release();
		return hr;
	}
	default:
		return E_UNEXPECTED;
	}
}

IFACEMETHODIMP ClassFactory::LockServer(BOOL fLock)
{
	if (fLock) {
		IncDllRef();
	} else {
		DecDllRef();
	}
	return S_OK;
}
