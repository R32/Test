package;

import mem.Ut;
import mem.Ptr;
import mem.Utf8;
import mem.Ucs2;
import mem.Alloc;
import mem.s.Block;
import mem.s.Md5;
import mem.s.Sha1;
import mem.s.Base64;
import mem.s.AES128;
import mem.s.AES128Embed;

class MemTest {

	@:access(mem)
	static function t_alloc() {
		function rand() return Mem.malloc(Std.int(512 * Math.random()) + 16);

		var ap = [];
		for (i in 0...512) ap.push(rand());    // alloc 512
		shuffle(ap);
		__eq(Alloc.length == 512 && Alloc.frags == 0);

		for (i in 0...256) Mem.free(ap.pop()); // free 256
		__eq(Alloc.length - Alloc.frags == 256);

		for (i in 0...256) ap.push(rand());    // alloc 256
		shuffle(ap);

		for (i in 0...256) Mem.free(ap.pop()); // free 256
		__eq(Alloc.length - Alloc.frags == 256);
		__eq(Alloc.simpleCheck());

		for (i in 0...256) Mem.free(ap.pop()); // free 256
		__eq(Alloc.length == 0 && Alloc.frags == 0 && Alloc.isEmpty());

		// realloc
		var x = Mem.malloc(128);
		x[0] = 101;
		x = Mem.realloc(x, 256);
		__eq(x[0] == 101 && Alloc.hd(x).entrySize >= 256);
		Mem.free(x);
		__eq(Alloc.length == 0 && Alloc.frags == 0 && Alloc.isEmpty());
	}

	static function t_utf8() {
		var s = "万般皆下品, 𨰻"; // 9
		var b = haxe.io.Bytes.ofString(s);
		var len = b.length;
		var p1: Ptr = Mem.malloc(len);
		var p3: Ptr = Mem.malloc(len);
		Mem.writeBytes(p1, len, b);

		var wlen = mem.Utf8.length(p1, len);
		__eq(wlen == 9);
		var p2: Ptr = Mem.malloc(wlen << 1);
		__eq(mem.Utf8.toUcs2(p2, p1, len) == wlen);
		__eq(mem.Utf8.ofUcs2(Ptr.NUL, p2, wlen) == len);

		__eq(mem.Utf8.ofUcs2(p3, p2, wlen) == len);
		__eq(Mem.memcmp(p1, p3, len) == 0);

		__eq(Utf8.ofString(Ptr.NUL, 0, s) == len);
		__eq(Utf8.ofString(p3, len, s) == len);
		__eq(Mem.memcmp(p1, p3, len) == 0);
		__eq(Utf8.getString(p3, len) == s);

		// ucs2
		__eq(Ucs2.getString(p2, wlen) == s);
		__eq(Ucs2.ofString(Ptr.NUL, wlen, s) == wlen);
		var p4: Ptr = Mem.malloc(wlen << 1);
		__eq(Ucs2.ofString(p4, wlen, s) == wlen);
		__eq(Mem.memcmp(p2, p4, wlen << 1) == 0);
		Mem.free(p1);
		Mem.free(p2);
		Mem.free(p3);
		Mem.free(p4);
		__eq(Alloc.length == 0 && Alloc.frags == 0 && Alloc.isEmpty());
	}

	static function t_mem() {
		// read/writeBytes
		var b = haxe.io.Bytes.ofString("hello world! (e=mc^2)");
		var len = b.length;
		var p1 = Mem.malloc(len);
		Mem.writeBytes(p1, len, b);

		var out = Mem.readBytes(p1, len);
		__eq(b.compare(out) == 0);

		// memcpy, memset, memcmp
		var p23 = Mem.malloc(128);
		var p2 = p23 + 64; // center
		Mem.memcpy(p2, p1, len);
		var out = Mem.readBytes(p2, len);
		__eq(b.compare(out) == 0 && Mem.memcmp(p1, p2, len) == 0);
		// memcpy(p2 - 1, p2)
		var p3 = p2 - 1;
		Mem.memcpy(p3, p2, len);
		__eq(Mem.memcmp(p1, p3, len) == 0);
		// memcpy(p3 + 1, p3)
		Mem.memcpy(p2, p3, len);
		__eq(Mem.memcmp(p1, p2, len) == 0);
		// memcpy(p2, p2)
		Mem.memcpy(p2, p2, len);
		__eq(Mem.memcmp(p1, p2, len) == 0);
		// memset
		var p3 = p2 + len;
		Mem.memset(p2, "a".code, len); Mem.memset(p3, "z".code, len);
		__eq(Mem.memcmp(p2, p3, len) < 0 && Mem.memcmp(p3, p2, len) > 0);

		// UTF8String, Block
		var name = "abc 与 中文字符";
		var ts = Mem.mallocFromString(name);
		__eq(ts.toString() == name);
		ts.free();
		var bk = Mem.mallocFromBytes(b);
		__eq(Mem.memcmp(bk, p1, len) == 0 && len == bk.length);
		bk.free();
		Mem.free(p1);
		Mem.free(p23);
		__eq(Alloc.length == 0 && Alloc.frags == 0 && Alloc.isEmpty());
	}

	static function t_md5() {
		function eq_md5(s: String) {
			var b = haxe.crypto.Md5.make( haxe.io.Bytes.ofString(s) );
			var ptrStr = Mem.mallocFromString(s);
			var ptrBlk1 = new mem.s.Block(16, false);
			Md5.make(ptrStr, ptrStr.length, ptrBlk1);

			var ptrBlk2 = Mem.mallocFromBytes(b);
			__eq(Mem.memcmp(ptrBlk2, ptrBlk1, ptrBlk2.length) == 0);
			ptrStr.free();
			ptrBlk1.free();
			ptrBlk2.free();
		}
		eq_md5("hello world!");
		eq_md5("0123456789");
		eq_md5("明月几时有 把酒问青天");
		Md5.destory();
	}

	static function t_sha1(){
		function eq_sha1(s: String) {
			var b = haxe.crypto.Sha1.make( haxe.io.Bytes.ofString(s) );
			var ptrStr = Mem.mallocFromString(s);
			var ptrBlk1 = new mem.s.Block(20, false);
			Sha1.make(ptrStr, ptrStr.length, ptrBlk1);
			var ptrBlk2 = Mem.mallocFromBytes(b);
			__eq(Mem.memcmp(ptrBlk2, ptrBlk1, ptrBlk2.length) == 0);
			ptrStr.free();
			ptrBlk1.free();
			ptrBlk2.free();
		}
		eq_sha1("hello world!");
		eq_sha1("0123456789");
		eq_sha1("明月几时有 把酒问青天");
		Sha1.destory();
	}

	static function t_base64() {
		var str = "hi 为什么这样子";
		var ptrStr = Mem.mallocFromString(str);
		var ptrB64 = Base64.encode(ptrStr, ptrStr.length);
		__eq( ptrB64.toString() == haxe.crypto.Base64.encode(haxe.io.Bytes.ofString(str)) );
		var ptrBlk = Base64.decode(ptrB64, ptrB64.length);
		__eq( Mem.memcmp(ptrStr, ptrBlk, ptrStr.length) == 0 );
		ptrStr.free();
		ptrBlk.free();
		ptrB64.free();
		Base64.destory();
	}

	static function t_aes128(){
		var text = [
			"6bc1bee22e409f96e93d7e117393172a",
			"ae2d8a571e03ac9c9eb76fac45af8e51",
			"30c81c46a35ce411e5fbc1191a0a52ef",
			"f69f2445df4f9b17ad2b417be66c3710"
		];
		var cipher = [
			"3ad77bb40d7a3660a89ecaf32466ef97",
			"f5d3d58503b9699de785895a96fdbaaf",
			"43b1cd7f598ece23881b00e3ed030688",
			"7b0c785e27e8ad3f8223207104725dd4"
		];
		inline function BLK_PCK5(size) return AES128.blkPK5(size);
		var ptrKey = Mem.mallocFromHex("2b7e151628aed2a6abf7158809cf4f3c");
		AES128.init(ptrKey);  // requered.
		for (i in 0...text.length) {
			var ptrStr = Mem.mallocFromHex(text[i]);
			var ptrBuf = BLK_PCK5(ptrStr.length);     // ptrBuf.length > ptrStr.length
			var ptrResult = Mem.mallocFromHex(cipher[i]);
			Mem.memcpy(ptrBuf, ptrStr, ptrStr.length);
			AES128.ecbEncrypt(ptrBuf);
			__eq(Mem.memcmp(ptrBuf, ptrResult, ptrResult.length) == 0);

			AES128.ecbDecrypt(ptrBuf);
			__eq(Mem.memcmp(ptrBuf, ptrStr, ptrStr.length) == 0);
			ptrStr.free();
			ptrBuf.free();
			ptrResult.free();
		}
		// AES CBC
		var ptrStr = Mem.mallocFromHex(text.join(""));
		var length = ptrStr.length;
		var ptrBuf = BLK_PCK5(length);
		Mem.memcpy(ptrBuf, ptrStr, length);

		var padded = AES128.cbcEncrypt(ptrBuf, length, ptrBuf.length);

		// reset IV, it's IMPORTANT
		AES128.setIv(Ptr.NUL);

		var result = AES128.cbcDecrypt(ptrBuf, ptrBuf.length);

		__eq(result == length && (Mem.memcmp(ptrBuf, ptrStr, result) == 0));

		ptrStr.free();
		ptrBuf.free();
		ptrKey.free();

		// AES CTR, there is no need to padding.
		var str = "Hi I'm trying to write a program that can compare two files line by line, word by word!";
		var ptrBuf = Mem.mallocFromString(str);
		var ptrKey = Mem.mallocFromString("0123456789ABCDEF");
		AES128.setKey(ptrKey);
		// AES CTR, encrypt
		AES128.setIv(Ptr.NUL);
		AES128.ctrXcrypt(ptrBuf, ptrBuf.length);
		// RESET,   decrypt use same function
		AES128.setIv(Ptr.NUL);
		AES128.ctrXcrypt(ptrBuf, ptrBuf.length);

		__eq(str == Utf8.getString(ptrBuf, ptrBuf.length));

		ptrKey.free();
		ptrBuf.free();
		AES128.destory();
	}

	// haxe generated too many unnecessary temporary variables
	static function too_many_local_var() {
		inline function rand() return MemTest.rand(100);
		var p = Mem.malloc(256);
		var i = 0;
		p[i++] = rand();
		p[i++] = rand();
		p[i++] = rand();

		var u8 = p.toAU8();
		u8[i++] = rand();
		u8[i++] = rand();
		u8[i++] = rand();

		var u16 = p.toAU16();
		u16[i++] = rand();
		u16[i++] = rand();
		u16[i++] = rand();


		var i32 = p.toAI32();
		i32[i++] = rand();
		i32[i++] = rand();
		i32[i++] = rand();

		var f32 = p.toAF4();
		f32[i++] = Math.random();
		f32[i++] = Math.random();
		f32[i++] = Math.random();

		var f64 = p.toAF8();
		f64[i++] = Math.random();
		f64[i++] = Math.random();
		f64[i++] = Math.random();
		Mem.free(p);
		__eq(Alloc.length == 0 && Alloc.frags == 0 && Alloc.isEmpty());
	}

	static function t_utils() {
		__eq(Ut.TRAILING_ONES(0x7FFFFFFF) == 31);
		__eq(Ut.TRAILING_ONES(0xFFFFFFF7) ==  3);
		__eq(Ut.TRAILING_ONES(0x00000000) ==  0);
		__eq(Ut.TRAILING_ONES(0xFFF0FFFF) == 16);
		__eq(Ut.TRAILING_ONES(0xFFFFFF0F) ==  4);
		__eq(Ut.align(0, 8) == 8 && Ut.align(8, 8) == 8 && Ut.align(1, 8) == 8 && Ut.align(9, 8) == 16);
	}

	static function t_struct() {
		// no idea.
		__eq(Monkey.CAPACITY == 16 + 1 + 4 + 32);

		// utf8, ucs2
		var jojo = new Monkey();
		var name = "乔乔";
		jojo.name = name;
		jojo.uname = name;
		__eq(jojo.uname == name && jojo.name == name);
		jojo.free();
	}
	///////

	static function __eq(b, ?pos: haxe.PosInfos) {
		if (!b) throw "ERROR: " + pos.lineNumber;
	}
	static function rand(max: Int, start = 0) {
		return Std.int(Math.random() * (max - start)) + start;
	}
	static function shuffle<T>(a: Array<T>, count = 1, start = 0) {
		var len = a.length;
		var r:Int, t:T;
		for (j in 0...count) {
			for (i in start...len) {
				r = rand(len, start);	// 0 ~ (len -1 )
				t = a[r];
				a[r] = a[i];
				a[i] = t;
			}
		}
	}
	static inline function platform() {
		return
		#if flash
		"flash";
		#elseif hl
		"hashlink";
		#elseif js
		"js";
		#elseif cpp
		"hxcpp";
		#elseif interp
		"interp";
		#else
		"others";
		#end
	}
	static function main() {
		Mem.init();
		t_utils();
		t_alloc();
		t_struct();
		t_mem();
		t_utf8();
		t_md5();
		t_sha1();
		t_base64();
		t_aes128();
		too_many_local_var();
		trace(platform() + " done!");
	}
}

enum abstract Color(Int) {
	var R = 1;
	var G = 1 << 1;
	var B = 1 << 2;
}

@:build(mem.Struct.build()) abstract Monkey(Ptr) {
	@idx(16) var name: String;    // 16bytes for name
	@idx var color: Color;        // same as Int, default is 1 byte.
	@idx var favor: Monkey;       // pointer to another,     4 bytes
	@idx(16) var uname: UCString; // (16 * 2) bytes, UCS2 String
}
@:build(mem.Struct.build()) abstract FlexibleStruct(Ptr) {
	@idx(4, -4) var length: Int; // @idx(bytes, offset); offset(relative to this) of the first field is -4
	@idx(0) var _b: AU8;         // Specify size by `new FlexibleStruct(size)` and the variable Type must be "array",
}
