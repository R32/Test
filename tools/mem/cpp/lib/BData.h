#ifndef INCLUDED_BDATA_
#define INCLUDED_BDATA_

#include "stdafx.h"

namespace mem {

	class BData {

	private:
		size_t  length;
		void* b;

		void select(void* alloc, size_t len);
	public:
		explicit BData(const BData& that);

		explicit BData(size_t len)
		{
			select(malloc(len), len);
		}

		inline const size_t Length() { return length; }

		inline void* Offset(int offset) {
			return (void*)(((uint8_t*) b) + offset);
		}

		void resize(size_t len);

		inline void removeData(){
			free(b);
			b = NULL;
		}

		inline uint8_t get(size_t pos)
		{
			assert(pos >= 0 && pos  < length);
			return ((uint8_t*) b)[pos];
		}
		inline void set(size_t pos, uint8_t v)
		{
			assert(pos >= 0 && pos  < length);
			((uint8_t*) b)[pos] = v;
		}

		//  src -> this[pos]
		inline void blit(size_t pos, BData* src, size_t srcpos, size_t len)
		{
			assert(!(pos < 0 || srcpos < 0 || len < 0 || pos + len > this->length || srcpos + len > src->length));
			::memcpy(Offset(pos), src->Offset(srcpos), len);
		}

		inline void fill(size_t pos, size_t len, uint8_t value)
		{
			assert(pos >= 0 && (pos + len) <= length);
			::memset(Offset(pos), value, len);
		}

		// -DNDEBUG defined in stdafx.h
		inline double getDouble(size_t pos)
		{
			assert(pos >= 0 && (pos + sizeof(double)) <= length);
			return *(double*)Offset(pos);
		}
		inline void setDouble(size_t pos, double v)
		 {
			assert(pos >= 0 && (pos + sizeof(double)) <= length);
			*(double*)Offset(pos) = v;
		}

		inline float getFloat(size_t pos)
		{
			assert(pos >= 0 && (pos + sizeof(float)) <= length);
			return *(float*)Offset(pos);
		}
		inline void setFloat(size_t pos, float v)
		{
			assert(pos >= 0 && (pos + sizeof(float)) <= length);
		 	*(float*)Offset(pos) = v;
		}

		inline uint16_t getUInt16(size_t pos)
		{
			assert(pos >= 0 && (pos + sizeof(uint16_t)) <= length);
			return *(uint16_t*)Offset(pos);
		}
		inline void setUInt16(size_t pos, uint16_t v)
		{
			assert(pos >= 0 && (pos + sizeof(uint16_t)) <= length);
			*(uint16_t*)Offset(pos) = v;
		}


		inline int32_t getInt32(size_t pos) {
			assert(pos >= 0 && (pos + sizeof(int32_t)) <= length);
			return *(int32_t*)Offset(pos);
		}
		inline void setInt32(size_t pos, int32_t v)
		{
			assert(pos >= 0 && (pos + sizeof(int32_t)) <= length);
		 	*(int32_t*)Offset(pos) = v;
		}

		inline int64_t getInt64(size_t pos)
		{
			assert(pos >= 0 && (pos + sizeof(int64_t)) <= length);
			return *(int64_t*)Offset(pos);
		}
		inline void setInt64(size_t pos, int64_t v)
		{
			assert(pos >= 0 && (pos + sizeof(int64_t)) <= length);
			*(int64_t*)Offset(pos) = v;
		}

		static void destory(BData* byte);
	};
}

#endif