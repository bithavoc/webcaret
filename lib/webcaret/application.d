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

    public:
        @property {
            string[string] params() nothrow {
                return _params;
            }
            void params(string[string] params) nothrow {
                _params = params;
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
            "listening http://%s:%d".format(address, port).writeln;
            server.listen ^^ (connection) {
                debug writeln("HTTP Agent just connected");
                connection.process ^^ (request, response) {
                    _router.execute(request.method, request.uri.path, cast(ApplicationHttpRequest)request, response);
                };
            };
        }
}

