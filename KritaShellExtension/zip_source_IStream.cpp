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

#include "zip_source_IStream.h"

#include <new>

namespace
{

inline zip_int64_t zip_source_IStream_read_data(void *state, void *data, zip_uint64_t len, zip_source_cmd_t cmd);
inline unsigned long long istream_read(IStream *pStream, void *data, unsigned long len, HRESULT *phResult);
inline unsigned long long istream_tell(IStream *pStream, HRESULT *phResult);
inline unsigned long long istream_seek(IStream *pStream, long long offset, DWORD origin, HRESULT *phResult);

struct read_data_ctx {
	zip_error_t error;
	HRESULT last_hResult;
	IStream *pStream;
};

} // namespace

zip_source_t *kritashellex::zip_source_IStream_create(IStream *pStream, zip_error_t *error)
{
	read_data_ctx *ctx = new (std::nothrow) read_data_ctx;
	if (!ctx) {
		zip_error_set(error, ZIP_ER_MEMORY, 0);
		return nullptr;
	}
	zip_error_init(&ctx->error);
	ctx->last_hResult = S_OK;
	ctx->pStream = pStream;
	pStream->AddRef();
	return zip_source_function_create(zip_source_IStream_read_data, ctx, error);
}

namespace
{

inline zip_int64_t zip_source_IStream_read_data(void *state, void *data, zip_uint64_t len, zip_source_cmd_t cmd)
{
	read_data_ctx *ctx = static_cast<read_data_ctx *>(state);

	switch (cmd) {
	case ZIP_SOURCE_CLOSE:
	case ZIP_SOURCE_OPEN:
		// These are handled elsewhere
		return 0;

	case ZIP_SOURCE_ERROR:
		return zip_error_to_data(&ctx->error, data, len);

	case ZIP_SOURCE_FREE:
		ctx->pStream->Release();
		delete ctx;
		return 0;

	case ZIP_SOURCE_READ:
		if (len > UINT32_MAX) {
			zip_error_set(&ctx->error, ZIP_ER_OPNOTSUPP, 0);
			return -1;
		}
		return istream_read(ctx->pStream, data, static_cast<unsigned long>(len), &ctx->last_hResult);

	case ZIP_SOURCE_SEEK:
	{
		zip_source_args_seek_t *args = ZIP_SOURCE_GET_ARGS(zip_source_args_seek_t, data, len, &ctx->error);
		if (!args) {
			return -1;
		}
		DWORD dwOrigin;
		switch (args->whence) {
		case SEEK_SET:
			dwOrigin = STREAM_SEEK_SET;
			break;
		case SEEK_END:
			dwOrigin = STREAM_SEEK_END;
			break;
		case SEEK_CUR:
			dwOrigin = STREAM_SEEK_CUR;
			break;
		default:
			zip_error_set(&ctx->error, ZIP_ER_INVAL, 0);
			return -1;
		}
		return istream_seek(ctx->pStream, args->offset, dwOrigin, &ctx->last_hResult);
	}

	case ZIP_SOURCE_STAT:
	{
		zip_stat_t *st = ZIP_SOURCE_GET_ARGS(zip_stat_t, data, len, &ctx->error);
		if (!st) {
			return -1;
		}

		zip_stat_init(st);

		STATSTG stat;

		HRESULT hr = ctx->pStream->Stat(&stat, STATFLAG_NONAME);
		if (FAILED(hr)) {
			zip_error_set(&ctx->error, ZIP_ER_INTERNAL, 0); // TODO
			ctx->last_hResult = hr;
			return -1;
		}
		st->mtime = 0;
		st->size = stat.cbSize.QuadPart;
		st->comp_size = stat.cbSize.QuadPart;
		st->comp_method = ZIP_CM_STORE;
		st->encryption_method = ZIP_EM_NONE;
		st->valid = ZIP_STAT_SIZE | ZIP_STAT_COMP_SIZE | ZIP_STAT_COMP_METHOD | ZIP_STAT_ENCRYPTION_METHOD;

		return sizeof(*st);
	}

	case ZIP_SOURCE_SUPPORTS:
		return ZIP_SOURCE_SUPPORTS_READABLE | ZIP_SOURCE_SUPPORTS_SEEKABLE;

	case ZIP_SOURCE_TELL:
		return static_cast<zip_int64_t>(istream_tell(ctx->pStream, &ctx->last_hResult));

	case ZIP_SOURCE_BEGIN_WRITE:
	case ZIP_SOURCE_COMMIT_WRITE:
	case ZIP_SOURCE_REMOVE:
	case ZIP_SOURCE_ROLLBACK_WRITE:
	case ZIP_SOURCE_SEEK_WRITE:
	case ZIP_SOURCE_TELL_WRITE:
	case ZIP_SOURCE_WRITE:
		zip_error_set(&ctx->error, ZIP_ER_RDONLY, 0);
		return -1;
	default:
		zip_error_set(&ctx->error, ZIP_ER_OPNOTSUPP, 0);
		return -1;
	}
}

inline unsigned long long istream_read(IStream *pStream, void *data, unsigned long len, HRESULT *phResult)
{
	ULONG cbRead;
	HRESULT hr = pStream->Read(data, len, &cbRead);
	if (FAILED(hr)) {
		if (phResult) {
			*phResult = hr;
		}
		return 0;
	}
	return cbRead;
}

inline unsigned long long istream_tell(IStream *pStream, HRESULT *phResult)
{
	LARGE_INTEGER pos;
	pos.QuadPart = 0;
	ULARGE_INTEGER newPos;
	HRESULT hr = pStream->Seek(pos, STREAM_SEEK_CUR, &newPos);
	if (FAILED(hr)) {
		if (phResult) {
			*phResult = hr;
		}
		return static_cast<unsigned long long>(-1);
	}
	return newPos.QuadPart;
}

inline unsigned long long istream_seek(IStream *pStream, long long offset, DWORD origin, HRESULT *phResult)
{
	LARGE_INTEGER pos;
	pos.QuadPart = offset;
	ULARGE_INTEGER newPos;
	HRESULT hr = pStream->Seek(pos, origin, &newPos);
	if (FAILED(hr)) {
		if (phResult) {
			*phResult = hr;
		}
		return -1;
	}
	return newPos.QuadPart;
}

} // namespace
