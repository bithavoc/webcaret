module webcaret.application;

import webcaret.router;
import heaploop.networking.http;
import heaploop.networking.tcp : TcpStream;
import std.string : format;
import std.stdio : writeln;

package:

class AppHttpServerConnection : HttpServerConnection {

    public:
        this(TcpStream stream) {
            super(stream);
        }

    protected:
        override HttpRequest createIncomingMessage() {
            return new ApplicationHttpRequest(this);
        }
}

class AppHttpListener : HttpListener {

    protected:
        override HttpServerConnection createConnection(TcpStream stream) {
            return new AppHttpServerConnection(stream);
        }
}

public:

class ApplicationHttpRequest : HttpRequest, IRoutedRequest {

    private:
        string[string] _params;
        string[string] _form;

package:

    void prepareRequest() {
        switch(this.contentType) {
            default:
                return;
            case "application/x-www-form-urlencoded": {
                ubyte[] formData;
                this.read ^= (chunk) {
                    formData ~= chunk.buffer;
                };
                string formText = cast(string)formData;
                this.form = parseURLEncodedForm(formText);
                break;
            }
            case "multipart/form-data": {
                assert(false, "multipart/form-data is not implemented yet, pull requests are welcome :)");
            }
        }
    }


    public:
        @property {
            string[string] params() nothrow {
                return _params;
            }
            void params(string[string] params) nothrow {
                _params = params;
            }
            string[string] form() nothrow {
                return _form;
            }
            void form(string[string] form) nothrow {
                _form = form;
            }
        }
        this(HttpServerConnection connection) {
            super(connection);
        }
}

class Application {
    private:
        Router!(ApplicationHttpRequest, HttpResponse) _router;

    public:
        this() {
            _router = new Router!(ApplicationHttpRequest, HttpResponse);
        }

        @property {
            Router!(ApplicationHttpRequest, HttpResponse) router() nothrow {
                return _router;
            }
        }

        void serve(string address, int port) {
            auto server = new AppHttpListener;
            server.bind4(address, port);
            "Web^ Application serving http://%s:%d".format(address, port).writeln;
            server.listen ^^= (connection) {
                debug writeln("HTTP Agent just connected");
                connection.process ^^= (request, response) {
                    auto appRequest = cast(ApplicationHttpRequest)request;
                    appRequest.prepareRequest();
                    _router.execute(request.method, request.uri.path, appRequest, response);
                };
            };
        }
}

