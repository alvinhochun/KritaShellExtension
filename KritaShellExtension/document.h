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

namespace kritashellex
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

class Document
{
private:
	const zip_ptr<zip_t> m_zf;
	enum { FILETYPE_UNKNOWN, FILETYPE_KRA, FILETYPE_ORA } m_fileType;
	unsigned int m_width;
	unsigned int m_height;
	double m_xRes;
	double m_yRes;
	bool m_init;

public:
	Document(zip_ptr<zip_t> zf);
	~Document();

	bool Init();

	unsigned int getWidth() const {
		return m_width;
	}

	unsigned int getHeight() const {
		return m_height;
	}

	double getXRes() const {
		return m_xRes;
	}

	double getYRes() const {
		return m_yRes;
	}

protected:
	bool readFile(const char *const filename, std::unique_ptr<char[]> &pContent_out, size_t &size_out) const;

private:
	bool parseKraMaindocXml(std::unique_ptr<char[]> pMaindoc, size_t maindocSize);
	bool parseOraStackXml(std::unique_ptr<char[]> pStackXml, size_t stackXmlSize);
};

} // namespace kritashellex
