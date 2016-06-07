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

#include "document.h"

#include <tinyxml2.h>

#include <new>

using namespace kritashellex;

Document::Document(zip_ptr<zip_t> zf, zip_ptr<zip_source_t> zsrc) :
	m_zsrc(std::move(zsrc)),
	m_zf(std::move(zf)),
	m_fileType(FILETYPE_UNKNOWN),
	m_width(0),
	m_height(0),
	m_xRes(0),
	m_yRes(0),
	m_init(false)
{
}

Document::Document(zip_ptr<zip_t> zf) :
	m_zsrc(nullptr),
	m_zf(std::move(zf)),
	m_fileType(FILETYPE_UNKNOWN),
	m_width(0),
	m_height(0),
	m_xRes(0),
	m_yRes(0),
	m_init(false)
{
}

Document::~Document()
{
}

bool Document::Init()
{
	if (m_init) {
		return false;
	}

	bool res;

	std::unique_ptr<char[]> pMimetypeContent;
	size_t mimetypeSize;
	// TODO: Rewrite this to prevent being zip-bombed.
	res = readFile("mimetype", pMimetypeContent, mimetypeSize);
	if (!res) {
		return false;
	}
	const char *const mimetypeKra = "application/x-krita";
	const char *const mimetypeOra = "image/openraster";
	if (mimetypeSize == std::strlen(mimetypeKra) && std::memcmp(pMimetypeContent.get(), mimetypeKra, std::strlen(mimetypeKra)) == 0) {
		m_fileType = FILETYPE_KRA;
		std::unique_ptr<char[]> pMaindocContent;
		size_t maindocContentSize;
		res = readFile("maindoc.xml", pMaindocContent, maindocContentSize);
		if (!res) {
			return false;
		}
		res = parseKraMaindocXml(std::move(pMaindocContent), maindocContentSize);
		if (!res) {
			return false;
		}
		m_init = true;
		return true;
	} else if (mimetypeSize == std::strlen(mimetypeOra) && std::memcmp(pMimetypeContent.get(), mimetypeOra, std::strlen(mimetypeOra)) == 0) {
		m_fileType = FILETYPE_ORA;
		std::unique_ptr<char[]> pStackXmlContent;
		size_t stackXmlContentSize;
		res = readFile("stack.xml", pStackXmlContent, stackXmlContentSize);
		if (!res) {
			return false;
		}
		res = parseOraStackXml(std::move(pStackXmlContent), stackXmlContentSize);
		if (!res) {
			return false;
		}
		m_init = true;
		return true;
	} else {
		return false;
	}
}

bool Document::readFile(const char *const filename, std::unique_ptr<char[]> &pContent_out, size_t &size_out) const
{
	// TODO: Handle errors from libzip?

	zip_stat_t fstat;
	if (zip_stat(m_zf.get(), filename, ZIP_FL_UNCHANGED, &fstat) != 0) {
		return false;
	}

	zip_ptr<zip_file_t> file(zip_fopen(m_zf.get(), filename, ZIP_FL_UNCHANGED));
	if (!file) {
		return false;
	}

	unsigned long long fileSize64 = fstat.size;
	size_t fileSize = static_cast<size_t>(fileSize64);
	if (fileSize != fileSize64) {
		return false;
	}

	std::unique_ptr<char[]> pContent(new (std::nothrow) char[fileSize]);
	if (!pContent) {
		return false;
	}

	int read = static_cast<int>(zip_fread(file.get(), pContent.get(), fileSize));
	if (read != fileSize) {
		return false;
	}

	pContent_out = std::move(pContent);
	size_out = fileSize;

	return true;
}

bool Document::parseKraMaindocXml(std::unique_ptr<char[]> pMaindoc, size_t maindocSize)
{
	tinyxml2::XMLDocument xmlDoc;
	tinyxml2::XMLError err;
	// tinyxml2 doesn't use std::nothrow in XMLDocument::Parse, so we'd catch the exception.
	try {
		err = xmlDoc.Parse(pMaindoc.get(), maindocSize);
	}
	catch (std::bad_alloc) {
		return false;
	}
	if (err != tinyxml2::XML_NO_ERROR) {
		return false;
	}

	// XMLDocument::Parse copies to an internal buffer so we can free the buffer already.
	pMaindoc.release();

	const tinyxml2::XMLElement *elemDoc = xmlDoc.FirstChildElement("DOC");
	if (!elemDoc) {
		return false;
	}

	const tinyxml2::XMLElement *elemImage = elemDoc->FirstChildElement("IMAGE");
	if (!elemImage) {
		return false;
	}

	err = elemImage->QueryUnsignedAttribute("width", &m_width);
	if (err != tinyxml2::XML_NO_ERROR) {
		return false;
	}

	err = elemImage->QueryUnsignedAttribute("height", &m_height);
	if (err != tinyxml2::XML_NO_ERROR) {
		return false;
	}

	err = elemImage->QueryDoubleAttribute("x-res", &m_xRes);
	if (err != tinyxml2::XML_NO_ERROR) {
		return false;
	}

	err = elemImage->QueryDoubleAttribute("y-res", &m_yRes);
	if (err != tinyxml2::XML_NO_ERROR) {
		return false;
	}

	return true;
}

bool Document::parseOraStackXml(std::unique_ptr<char[]> pStackXml, size_t pStackXmlSize)
{
	tinyxml2::XMLDocument xmlDoc;
	tinyxml2::XMLError err;
	// tinyxml2 doesn't use std::nothrow in XMLDocument::Parse, so we'd catch the exception.
	try {
		err = xmlDoc.Parse(pStackXml.get(), pStackXmlSize);
	}
	catch (std::bad_alloc) {
		return false;
	}
	if (err != tinyxml2::XML_NO_ERROR) {
		return false;
	}

	// XMLDocument::Parse copies to an internal buffer so we can free the buffer already.
	pStackXml.release();

	const tinyxml2::XMLElement *elemImage = xmlDoc.FirstChildElement("image");
	if (!elemImage) {
		return false;
	}

	err = elemImage->QueryUnsignedAttribute("w", &m_width);
	if (err != tinyxml2::XML_NO_ERROR) {
		return false;
	}

	err = elemImage->QueryUnsignedAttribute("h", &m_height);
	if (err != tinyxml2::XML_NO_ERROR) {
		return false;
	}

	// These are optional according to OpenRaster spec
	elemImage->QueryDoubleAttribute("xres", &m_xRes);
	elemImage->QueryDoubleAttribute("yres", &m_yRes);

	return true;
}
