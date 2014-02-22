// D import file generated from 'lib/http/parser/c.d'
module http.parser.c;
import std.conv;
import std.c.stdlib;
import std.stdint;
import std.bitmanip;
import std.stdint;
extern (C) 
{
	struct http_parser;
	alias int function(http_parser*, ubyte* at, size_t length) http_data_cb;
	alias int function(http_parser*) http_cb;
	enum http_parser_type 
	{
		HTTP_REQUEST,
		HTTP_RESPONSE,
		HTTP_BOTH,
	}
	struct http_parser_settings
	{
		http_cb on_message_begin;
		http_data_cb on_url;
		http_data_cb on_status_complete;
		http_data_cb on_header_field;
		http_data_cb on_header_value;
		http_cb on_headers_complete;
		http_data_cb on_body;
		http_cb on_message_complete;
	}
	void http_parser_init(http_parser* parser, http_parser_type type);

	size_t http_parser_execute(http_parser* parser, http_parser_settings* settings, ubyte* data, size_t len);

	const(char)* duv_http_errno_name(http_parser* parser);

	const(char)* duv_http_errno_description(http_parser* parser);

	http_parser* duv_alloc_http_parser();

	void duv_free_http_parser(http_parser* parser);

	void duv_set_http_parser_data(http_parser* parser, void* data);

	void* duv_get_http_parser_data(http_parser* parser);

	ubyte duv_http_parser_get_errno(http_parser* parser);

	template http_parser_cb(string Name)
	{
		const char[] http_parser_cb = "static int duv_http_parser_" ~ Name ~ "(http_parser * parser) { void * _self = duv_get_http_parser_data(parser); HttpParser self = cast(HttpParser)_self; return self._" ~ Name ~ "(); }";

	}
	template http_parser_data_cb(string Name)
	{
		const char[] http_parser_data_cb = "static int duv_http_parser_" ~ Name ~ "(http_parser * parser, ubyte * at, size_t len) { HttpParser self = cast(HttpParser)duv_get_http_parser_data(parser); return self._" ~ Name ~ "(at[0 .. len]); }";

	}
	immutable(char)* duv_http_method_str(http_parser* parser);

	ushort duv_http_major(http_parser* parser);

	ushort duv_http_minor(http_parser* parser);

	uint duv_http_status_code(http_parser* parser);

	enum http_parser_url_fields 
	{
		UF_SCHEMA = 0,
		UF_HOST = 1,
		UF_PORT = 2,
		UF_PATH = 3,
		UF_QUERY = 4,
		UF_FRAGMENT = 5,
		UF_USERINFO = 6,
		UF_MAX = 7,
	}
	struct http_parser_url;
	int http_parser_parse_url(immutable(char)* buf, size_t buflen, int is_connect, http_parser_url* u);

	size_t http_parser_url_size();

	http_parser_url* alloc_http_parser_url()
	{
		return cast(http_parser_url*)malloc(http_parser_url_size());
	}

	void free_http_parser_url(http_parser_url* u)
	{
		if (u !is null)
		{
			free(cast(void*)u);
		}
	}

	struct http_parser_url_field
	{
		uint16_t off;
		uint16_t len;
	}
	http_parser_url_field http_parser_get_field(http_parser_url* url, http_parser_url_fields field);

	uint16_t http_parser_get_port(http_parser_url* url);

	uint16_t http_parser_get_fieldset(http_parser_url* url);

	string http_parser_get_field_string(http_parser_url* url, string rawUri, http_parser_url_fields field)
	{
		auto fieldset = http_parser_get_fieldset(url);
		auto f = http_parser_get_field(url, field);
		auto ifs = fieldset & 1 << field;
		string data = null;
		if (ifs != 0)
		{
			data = rawUri[f.off..f.off + f.len];
		}
		return data;
	}

	int http_body_is_final(http_parser* parser);

	ulong http_parser_get_content_length(http_parser* parser);

}
