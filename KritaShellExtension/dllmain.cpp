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

#include "ClassFactory.h"
#include "dllmain.h"

#include <new>

#include <windows.h>
#include <shlobj.h>
#include <shlwapi.h>
#include <strsafe.h>

#pragma comment(lib, "shlwapi.lib")

// CLSID of KritaThumbnailProvider
// {C6806289-D605-4AFE-A778-BC584303DB9A}
#define szCLSID_KritaThumbnailProvider L"{C6806289-D605-4AFE-A778-BC584303DB9A}"
const CLSID CLSID_KritaThumbnailProvider =
{ 0xc6806289, 0xd605, 0x4afe, { 0xa7, 0x78, 0xbc, 0x58, 0x43, 0x3, 0xdb, 0x9a } };

// CLSID of KritaPropertyHandler
// {C8E5509D-6F68-480C-8A41-DB64AECE94C6}
#define szCLSID_KritaPropertyHandler L"{C8E5509D-6F68-480C-8A41-DB64AECE94C6}"
const CLSID CLSID_KritaPropertyHandler =
{ 0xc8e5509d, 0x6f68, 0x480c,{ 0x8a, 0x41, 0xdb, 0x64, 0xae, 0xce, 0x94, 0xc6 } };


namespace
{

struct REGKEY_DELETEKEY
{
	HKEY hKey;
	LPCWSTR lpszSubKey;
};


struct REGKEY_SUBKEY_AND_VALUE
{
	HKEY hKey;
	LPCWSTR lpszSubKey;
	LPCWSTR lpszValue;
	DWORD dwType;
	DWORD_PTR dwData;
};


HINSTANCE u_hInstance = nullptr;
unsigned long u_dllRefCount = 0;

HRESULT CreateRegistryKeys(REGKEY_SUBKEY_AND_VALUE* aKeys, ULONG cKeys);
HRESULT DeleteRegistryKeys(REGKEY_DELETEKEY* aKeys, ULONG cKeys);

}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
	switch (ul_reason_for_call) {
	case DLL_PROCESS_ATTACH:
		u_hInstance = hModule;
		DisableThreadLibraryCalls(hModule);
		break;
	case DLL_THREAD_ATTACH:
	case DLL_THREAD_DETACH:
	case DLL_PROCESS_DETACH:
		break;
	}
	return TRUE;
}

STDAPI DllRegisterServer(void)
{
	WCHAR szModule[MAX_PATH] = { 0 };
	HRESULT hr;

	if (GetModuleFileName(u_hInstance, szModule, ARRAYSIZE(szModule)) == 0) {
		return HRESULT_FROM_WIN32(GetLastError());
	}

	// Register thumbnail provider
	REGKEY_SUBKEY_AND_VALUE keys_thumbnailprovider[] = {
		{ HKEY_CLASSES_ROOT, L"CLSID\\" szCLSID_KritaThumbnailProvider, nullptr, REG_SZ, (DWORD_PTR)L"Krita Thumbnail Provider" },
#if _DEBUG
		// For easier debugging only!
		// Make sure to unregister and re-register extension to remove this key when switching between config
		{ HKEY_CLASSES_ROOT, L"CLSID\\" szCLSID_KritaThumbnailProvider, L"DisableProcessIsolation", REG_DWORD, 1 },
#endif
		{ HKEY_CLASSES_ROOT, L"CLSID\\" szCLSID_KritaThumbnailProvider L"\\InprocServer32", nullptr, REG_SZ, (DWORD_PTR)szModule },
		{ HKEY_CLASSES_ROOT, L"CLSID\\" szCLSID_KritaThumbnailProvider L"\\InprocServer32", L"ThreadingModel", REG_SZ, (DWORD_PTR)L"Apartment" },
		{ HKEY_CLASSES_ROOT, L".kra\\shellex\\{E357FCCD-A995-4576-B01F-234630154E96}", nullptr, REG_SZ, (DWORD_PTR)szCLSID_KritaThumbnailProvider },
	};
	hr = CreateRegistryKeys(keys_thumbnailprovider, ARRAYSIZE(keys_thumbnailprovider));
	if (FAILED(hr)) {
		// Undo the changes?...
		// TODO: Keep track of what to actually delete
		REGKEY_DELETEKEY delete_keys[] = {
			{ HKEY_CLASSES_ROOT, L".kra\\shellex\\{E357FCCD-A995-4576-B01F-234630154E96}" },
			{ HKEY_CLASSES_ROOT, L"CLSID\\" szCLSID_KritaThumbnailProvider },
		};
		DeleteRegistryKeys(delete_keys, ARRAYSIZE(delete_keys)); // Don't care if this fails
		return hr;
	}

	// Register property handler
	REGKEY_SUBKEY_AND_VALUE keys_propertyHandler[] = {
		{ HKEY_CLASSES_ROOT, L"CLSID\\" szCLSID_KritaPropertyHandler, nullptr, REG_SZ, (DWORD_PTR)L"Krita Property Handler" },
#if _DEBUG
		// For easier debugging only!
		// Make sure to unregister and re-register extension to remove this key when switching between config
		{ HKEY_CLASSES_ROOT, L"CLSID\\" szCLSID_KritaPropertyHandler, L"DisableProcessIsolation", REG_DWORD, 1 },
#endif
		{ HKEY_CLASSES_ROOT, L"CLSID\\" szCLSID_KritaPropertyHandler L"\\InprocServer32", nullptr, REG_SZ, (DWORD_PTR)szModule },
		{ HKEY_CLASSES_ROOT, L"CLSID\\" szCLSID_KritaPropertyHandler L"\\InprocServer32", L"ThreadingModel", REG_SZ, (DWORD_PTR)L"Apartment" },
		{ HKEY_CLASSES_ROOT, L".kra", L"PerceivedType", REG_SZ, (DWORD_PTR)L"Image" },
		{ HKEY_LOCAL_MACHINE, L"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\PropertySystem\\PropertyHandlers\\.kra", nullptr, REG_SZ, (DWORD_PTR)szCLSID_KritaPropertyHandler },
	};
	hr = CreateRegistryKeys(keys_propertyHandler, ARRAYSIZE(keys_propertyHandler));
	if (FAILED(hr)) {
		// Undo the changes?...
		// TODO: Keep track of what to actually delete
		REGKEY_DELETEKEY delete_keys[] = {
			{ HKEY_LOCAL_MACHINE, L"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\PropertySystem\\PropertyHandlers\\.kra" },
			{ HKEY_CLASSES_ROOT, L"CLSID\\" szCLSID_KritaPropertyHandler },
		};
		DeleteRegistryKeys(delete_keys, ARRAYSIZE(delete_keys)); // Don't care if this fails
		return hr;
	}

	// Notify shell about file association changes
	SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nullptr, nullptr);

	return S_OK;
}

STDAPI DllUnregisterServer(void)
{
	WCHAR szModule[MAX_PATH] = { 0 };

	if (GetModuleFileName(u_hInstance, szModule, ARRAYSIZE(szModule)) == 0) {
		return HRESULT_FROM_WIN32(GetLastError());
	}

	REGKEY_DELETEKEY keys[] = {
		{ HKEY_CLASSES_ROOT, L"CLSID\\" szCLSID_KritaThumbnailProvider },
		{ HKEY_CLASSES_ROOT, L"CLSID\\" szCLSID_KritaPropertyHandler },
	};
	HRESULT hr = DeleteRegistryKeys(keys, ARRAYSIZE(keys));

	// We don't care about this failing.
	// One of the 32-bit and 64-bit versions could have already deleted this.
	REGKEY_DELETEKEY keys2[] = {
		{ HKEY_CLASSES_ROOT, L".kra\\shellex\\{E357FCCD-A995-4576-B01F-234630154E96}" },
		{ HKEY_LOCAL_MACHINE, L"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\PropertySystem\\PropertyHandlers\\.kra" },
	};
	DeleteRegistryKeys(keys2, ARRAYSIZE(keys2));
	return hr;
}

STDAPI DllCanUnloadNow(void)
{
	return u_dllRefCount > 0 ? S_FALSE : S_OK;
}

STDAPI DllGetClassObject(REFCLSID rclsid, REFIID riid, void **ppv)
{
	using namespace kritashellex;

	ClassFactory::Type type;
	if (IsEqualCLSID(CLSID_KritaThumbnailProvider, rclsid)) {
		type = ClassFactory::CLASS_THUMBNAIL;
	} else if (IsEqualCLSID(CLSID_KritaPropertyHandler, rclsid)) {
		type = ClassFactory::CLASS_PROPERTY;
	} else {
		return CLASS_E_CLASSNOTAVAILABLE;
	}

	ClassFactory *pClassFactory = new (std::nothrow) kritashellex::ClassFactory(type);
	if (!pClassFactory) {
		return E_OUTOFMEMORY;
	}

	HRESULT hr = pClassFactory->QueryInterface(riid, ppv);
	pClassFactory->Release();
	return hr;
}

void kritashellex::IncDllRef(void)
{
	InterlockedIncrement(&u_dllRefCount);
}

void kritashellex::DecDllRef(void)
{
	InterlockedDecrement(&u_dllRefCount);
}

namespace
{

HRESULT CreateRegistryKey(REGKEY_SUBKEY_AND_VALUE* pKey)
{
	size_t cbData;
	LPVOID pvData = nullptr;
	HRESULT hr = S_OK;

	switch (pKey->dwType) {
	case REG_DWORD:
		pvData = (LPVOID)(LPDWORD)&pKey->dwData;
		cbData = sizeof(DWORD);
		break;

	case REG_SZ:
	case REG_EXPAND_SZ:
		hr = StringCbLength((LPCWSTR)pKey->dwData, STRSAFE_MAX_CCH, &cbData);
		if (SUCCEEDED(hr)) {
			pvData = (LPVOID)(LPCWSTR)pKey->dwData;
			cbData += sizeof(WCHAR);
		}
		break;

	default:
		hr = E_INVALIDARG;
	}

	if (SUCCEEDED(hr)) {
		LSTATUS status = SHSetValue(pKey->hKey, pKey->lpszSubKey, pKey->lpszValue, pKey->dwType, pvData, (DWORD)cbData);
		if (status != NOERROR) {
			hr = HRESULT_FROM_WIN32(status);
		}
	}

	return hr;
}

HRESULT CreateRegistryKeys(REGKEY_SUBKEY_AND_VALUE* aKeys, ULONG cKeys)
{
	HRESULT hr = S_OK;

	for (ULONG iKey = 0; iKey < cKeys; iKey++) {
		HRESULT hrTemp = CreateRegistryKey(&aKeys[iKey]);
		if (FAILED(hrTemp)) {
			hr = hrTemp;
		}
	}
	return hr;
}

HRESULT DeleteRegistryKeys(REGKEY_DELETEKEY* aKeys, ULONG cKeys)
{
	HRESULT hr = S_OK;
	LSTATUS status;

	for (ULONG iKey = 0; iKey < cKeys; iKey++) {
		status = RegDeleteTree(aKeys[iKey].hKey, aKeys[iKey].lpszSubKey);
		if (status != NOERROR) {
			hr = HRESULT_FROM_WIN32(status);
		}
	}
	return hr;
}

} // namespace
