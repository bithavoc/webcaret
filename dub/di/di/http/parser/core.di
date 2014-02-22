// D import file generated from 'lib/http/parser/core.d'
module http.parser.core;
import http.parser.c;
import std.stdio;
import std.conv;
import std.string : toStringz, CaseSensitive, indexOf;
import std.stdint : uint16_t;
enum HttpParserType 
{
	REQUEST,
	RESPONSE,
	BOTH,
}
enum HttpBodyTransmissionMode 
{
	None,
	ContentLength,
	Chunked,
}
@property pure nothrow bool shouldRead(HttpBodyTransmissionMode mode)
{
	return mode > HttpBodyTransmissionMode.None;
}


public struct HttpVersion
{
	private 
	{
		ushort _minor;
		ushort _major;
		string _str;
		public 
		{
			this(ushort major, ushort minor)
			{
				_major = major;
				_minor = minor;
				_str = std.string.format("%d.%d", _major, _minor);
			}

			@property 
			{
				pure nothrow ushort major()
				{
					return _major;
				}

				pure nothrow ushort minor()
				{
					return _minor;
				}

			}
			string toString()
			{
				return _str;
			}

		}
	}
}

public struct HttpHeader
{
	package 
	{
		string _name;
		string _value;
	}
	public 
	{
		@property string name()
		{
			return _name;
		}


		@property void name(string name)
		{
			_name = name;
		}


		@property string value()
		{
			return _value;
		}


		@property void value(string value)
		{
			_value = value;
		}


		@property bool hasValue()
		{
			return _value !is null;
		}


		@property bool hasName()
		{
			return _name !is null;
		}


		@property bool isEmpty()
		{
			return !hasName() && !hasValue();
		}


	}
}

public class HttpParserException : Exception
{
	private string _name;

	public this(string message, string name, string filename = __FILE__, size_t line = __LINE__, Throwable next = null)
	{
		super(message, filename, line, next);
	}


	public @property string name()
	{
		return _name;
	}



	public @property void name(string name)
	{
		_name = name;
	}



}

public struct HttpBodyChunk
{
	private 
	{
		ubyte[] _buffer;
		bool _isFinal;
		public 
		{
			this(ubyte[] buffer, bool isFinal)
			{
				_buffer = buffer;
				_isFinal = isFinal;
			}

			@property 
			{
				pure nothrow bool isFinal()
				{
					return _isFinal;
				}

				pure nothrow ubyte[] buffer()
				{
					return _buffer;
				}

			}
		}
	}
}

public alias void delegate(HttpParser) HttpParserDelegate;

public alias void delegate(HttpParser, HttpBodyChunk) HttpParserBodyChunkDelegate;

public alias void delegate(HttpParser, string data) HttpParserStringDelegate;

public alias void delegate(HttpParser, HttpHeader header) HttpParserHeaderDelegate;

public class HttpParser
{
	private 
	{
		extern (C) 
		{
			mixin(http_parser_cb!"on_message_begin");
			mixin(http_parser_data_cb!"on_url");
			mixin(http_parser_data_cb!"on_status_complete");
			mixin(http_parser_data_cb!"on_header_value");
			mixin(http_parser_data_cb!"on_header_field");
			mixin(http_parser_cb!"on_headers_complete");
			mixin(http_parser_data_cb!"on_body");
			mixin(http_parser_cb!"on_message_complete");
		}
		http_parser* _parser;
		http_parser_settings _settings;
		HttpParserType _type;
		HttpParserDelegate _messageBegin;
		HttpParserDelegate _messageComplete;
		HttpParserDelegate _headersComplete;
		HttpParserBodyChunkDelegate _onBody;
		HttpParserStringDelegate _onUrl;
		HttpParserStringDelegate _statusComplete;
		HttpParserHeaderDelegate _onHeader;
		Throwable _lastException;
		HttpBodyTransmissionMode _transmissionMode;
		bool _transferEncodingPresent = false;
		const int CB_OK = 0;

		const int CB_ERR = 1;

		int _headerFields;
		int _headerValues;
		HttpHeader _currentHeader;
		void _resetCounters()
		{
			_transferEncodingPresent = false;
			_headerFields = 0;
			_headerValues = 0;
			_resetCurrentHeader();
		}

		void _resetCurrentHeader()
		{
			clear(_currentHeader);
		}

	}
	public 
	{
		this()
		{
			this(HttpParserType.REQUEST);
		}

		this(HttpParserType type)
		{
			_type = type;
			_parser = duv_alloc_http_parser();
			duv_set_http_parser_data(_parser, cast(void*)this);
			http_parser_init(_parser, cast(http_parser_type)type);
			_settings.on_message_begin = &duv_http_parser_on_message_begin;
			_settings.on_message_complete = &duv_http_parser_on_message_complete;
			_settings.on_status_complete = &duv_http_parser_on_status_complete;
			_settings.on_header_field = &duv_http_parser_on_header_field;
			_settings.on_header_value = &duv_http_parser_on_header_value;
			_settings.on_headers_complete = &duv_http_parser_on_headers_complete;
			_settings.on_body = &duv_http_parser_on_body;
			_settings.on_url = &duv_http_parser_on_url;
		}

		size_t execute(string text)
		{
			return execute(cast(ubyte[])text);
		}

		size_t execute(ubyte[] data)
		{
			_lastException = null;
			size_t inputLength = data.length;
			size_t ret = http_parser_execute(_parser, &_settings, cast(ubyte*)data, inputLength);
			auto error = duv_http_parser_get_errno(_parser);
			if (_lastException || error || ret != inputLength)
			{
				if (_lastException)
				{
					throw _lastException;
				}
				const(char)* errName = duv_http_errno_name(_parser);
				const(char)* errDescription = duv_http_errno_description(_parser);
				string errNameStr = to!string(errName);
				string errDescStr = to!string(errDescription);
				throw new HttpParserException(errDescStr, errNameStr);
			}
			return ret;
		}

		@property HttpVersion protocolVersion()
		{
			return HttpVersion(duv_http_major(_parser), duv_http_minor(_parser));
		}


		@property HttpParserType type()
		{
			return _type;
		}


		@property HttpParserDelegate onMessageBegin()
		{
			return _messageBegin;
		}


		@property void onMessageBegin(HttpParserDelegate callback)
		{
			_messageBegin = callback;
		}


		@property HttpParserDelegate onMessageComplete()
		{
			return _messageComplete;
		}


		@property void onMessageComplete(HttpParserDelegate callback)
		{
			_messageComplete = callback;
		}


		@property HttpParserStringDelegate onStatusComplete()
		{
			return _statusComplete;
		}


		@property void onStatusComplete(HttpParserStringDelegate callback)
		{
			_statusComplete = callback;
		}


		@property HttpParserDelegate onHeadersComplete()
		{
			return _headersComplete;
		}


		@property void onHeadersComplete(HttpParserDelegate callback)
		{
			_headersComplete = callback;
		}


		@property HttpParserBodyChunkDelegate onBody()
		{
			return _onBody;
		}


		@property void onBody(HttpParserBodyChunkDelegate callback)
		{
			_onBody = callback;
		}


		@property HttpParserStringDelegate onUrl()
		{
			return _onUrl;
		}


		@property void onUrl(HttpParserStringDelegate callback)
		{
			_onUrl = callback;
		}


		@property HttpParserHeaderDelegate onHeader()
		{
			return _onHeader;
		}


		@property void onHeader(HttpParserHeaderDelegate callback)
		{
			_onHeader = callback;
		}


		@property string method()
		{
			return std.conv.to!string(duv_http_method_str(_parser));
		}


		@property ulong contentLength()
		{
			return http_parser_get_content_length(_parser);
		}


		@property HttpBodyTransmissionMode transmissionMode()
		{
			return _transmissionMode;
		}


	}
	package 
	{
		int _on_message_begin()
		{
			_resetCounters();
			if (this._messageBegin)
			{
				try
				{
					_messageBegin(this);
				}
				catch(Throwable ex)
				{
					_lastException = ex;
					return CB_ERR;
				}
			}
			return CB_OK;
		}

		int _on_message_complete()
		{
			if (this._messageComplete)
			{
				try
				{
					_messageComplete(this);
				}
				catch(Throwable ex)
				{
					_lastException = ex;
					return CB_ERR;
				}
			}
			return CB_OK;
		}

		int _on_status_complete(ubyte[] data)
		{
			if (this._statusComplete)
			{
				try
				{
					_statusComplete(this, cast(string)data);
				}
				catch(Throwable ex)
				{
					_lastException = ex;
					return CB_ERR;
				}
			}
			return CB_OK;
		}

		int _on_url(ubyte[] data)
		{
			if (this._onUrl)
			{
				try
				{
					_onUrl(this, cast(string)data);
				}
				catch(Throwable ex)
				{
					_lastException = ex;
					return CB_ERR;
				}
			}
			return CB_OK;
		}

		int _on_header_field(ubyte[] data)
		{
			if (_currentHeader.hasValue)
			{
				int res = _safePublishHeader();
				_resetCurrentHeader();
				if (res != CB_OK)
				{
					return res;
				}
			}
			string text = cast(string)data;
			_currentHeader._name ~= text;
			return CB_OK;
		}

		int _on_header_value(ubyte[] data)
		{
			string text = cast(string)data;
			_currentHeader._value ~= text;
			return CB_OK;
		}

		int _safePublishHeader()
		{
			try
			{
				_publishHeader();
			}
			catch(Throwable ex)
			{
				_lastException = ex;
				return CB_ERR;
			}
			return CB_OK;
		}

		void _publishHeader()
		{
			if (_currentHeader.isEmpty)
				return ;
			if (_currentHeader.name.indexOf("Transfer-Encoding", CaseSensitive.no) != -1)
			{
				_transferEncodingPresent = true;
			}
			if (this._onHeader)
			{
				this._onHeader(this, _currentHeader);
			}
		}

		void _determinateTransmissionMode()
		{
			if (_transferEncodingPresent)
			{
				_transmissionMode = HttpBodyTransmissionMode.Chunked;
			}
			else
				if (this.contentLength > 0)
				{
					_transmissionMode = HttpBodyTransmissionMode.ContentLength;
				}
				else
				{
					_transmissionMode = HttpBodyTransmissionMode.None;
				}
		}

		int _on_headers_complete()
		{
			try
			{
				_publishHeader();
				_determinateTransmissionMode();
				if (this._headersComplete)
				{
					_headersComplete(this);
				}
			}
			catch(Throwable ex)
			{
				_lastException = ex;
				return CB_ERR;
			}
			return CB_OK;
		}

		int _on_body(ubyte[] data)
		{
			if (this._onBody)
			{
				try
				{
					bool isFinal = http_body_is_final(_parser) != 0;
					auto chunk = HttpBodyChunk(data, isFinal);
					_onBody(this, chunk);
				}
				catch(Throwable ex)
				{
					_lastException = ex;
					return CB_ERR;
				}
			}
			return CB_OK;
		}

	}
	~this()
	{
		if (_parser)
		{
			duv_free_http_parser(_parser);
			_parser = null;
		}
	}
}

struct Uri
{
	private 
	{
		string _schema;
		string _host;
		string _path;
		string _query;
		string _fragment;
		string _userInfo;
		ushort _port;
		string _absoluteUri;
		void buildAbsoluteUri()
		{
			string absolutePort = _port == 0 ? "" : ":" ~ _port.to!string;
			string absoluteQuery = _query.length == 0 ? "" : "?" ~ _query;
			string absoluteUserInfo = _userInfo.length == 0 ? "" : _userInfo ~ "@";
			_absoluteUri = this.schema ~ "://" ~ absoluteUserInfo ~ _host ~ absolutePort ~ _path ~ absoluteQuery;
		}

		public 
		{
			this(in string rawUri, bool isConnect = false)
			{
				http_parser_url* url = alloc_http_parser_url();
				scope(exit) free_http_parser_url(url);
				immutable(char)* buff = rawUri.toStringz;
				int res = http_parser_parse_url(buff, rawUri.length, isConnect ? 1 : 0, url);
				if (res != 0)
				{
					throw new Exception("Failed to parse rawUri " ~ rawUri);
				}
				auto port = http_parser_get_port(url);
				auto schema = http_parser_get_field_string(url, rawUri, http_parser_url_fields.UF_SCHEMA);
				auto host = http_parser_get_field_string(url, rawUri, http_parser_url_fields.UF_HOST);
				auto path = http_parser_get_field_string(url, rawUri, http_parser_url_fields.UF_PATH);
				auto query = http_parser_get_field_string(url, rawUri, http_parser_url_fields.UF_QUERY);
				auto fragment = http_parser_get_field_string(url, rawUri, http_parser_url_fields.UF_FRAGMENT);
				auto userInfo = http_parser_get_field_string(url, rawUri, http_parser_url_fields.UF_USERINFO);
				this(schema, host, port, path, query, fragment, userInfo);
			}

			this(in string schema, in string host, in ushort port, in string path, in string query, in string fragment, in string userInfo)
			{
				_schema = schema;
				_host = host;
				_port = port;
				_path = path;
				_query = query;
				_fragment = fragment;
				_userInfo = userInfo;
				this.buildAbsoluteUri();
			}

			@property 
			{
				pure nothrow string schema()
				{
					return _schema;
				}

				pure nothrow string host()
				{
					return _host;
				}

				pure nothrow ushort port()
				{
					return _port;
				}

				pure nothrow string path()
				{
					return _path;
				}

				pure nothrow string query()
				{
					return _query;
				}

				pure nothrow string fragment()
				{
					return _fragment;
				}

				pure nothrow string userInfo()
				{
					return _userInfo;
				}

				pure nothrow string absoluteUri()
				{
					return _absoluteUri;
				}

			}
			string toString()
			{
				return this.absoluteUri;
			}

		}
	}
}
