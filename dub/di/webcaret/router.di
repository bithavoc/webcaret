// D import file generated from 'webcaret/router.d'
module webcaret.router;
import events;
import std.string : toUpper, toLower;
import std.regex;
package 
{
	template Route(TRequest : IRoutedRequest, TResponse)
	{
		class Route : EventList!(void, TRequest, TResponse)
		{
			private 
			{
				string _path;
				Regex!char _compiledPath;
				string[] _routeParams;
				EventList!(void, TRequest, TResponse).Trigger _eventTrigger;
				public 
				{
					this(string path)
					{
						_path = path;
						_eventTrigger = this.own;
						_routeParams = extractRouteParams;
						_compiledPath = compilePathRegex;
					}

					@property string path()
					{
						return _path;
					}


					@property string[] routeParams()
					{
						return _routeParams;
					}


					@property Regex!char compiledPath()
					{
						return _compiledPath;
					}


					void execute(string uri, TRequest request, TResponse response)
					{
						auto m = match(uri, _compiledPath);
						string[string] params;
						if (m.captures.length > 0)
						{
							for (int i = 1;
							 i < m.captures.length; i++)
							{
								{
									params[_routeParams[i - 1]] = m.captures[i];
								}
							}
							request.params = params;
							_eventTrigger(request, response);
						}
					}

					private 
					{
						string[] extractRouteParams()
						{
							string[] keys;
							string c;
							foreach (m; match(_path, regex("(:\\w+)", "gm")))
							{
								c = m.captures[1];
								keys ~= c[1..c.length];
							}
							return keys;
						}

						Regex!char compilePathRegex()
						{
							auto replaced = replaceAll(_path, regex("(:\\w+)", "g"), "([^/?#]+)");
							auto compiledRegexp = regex(replaced);
							return compiledRegexp;
						}

					}
				}
			}
		}
	}
	public 
	{
		interface IRoutedRequest
		{
			@property 
			{
				string[string] params();

				void params(string[string] params);

			}
		}
		template VerbHandler(TRequest : IRoutedRequest, TResponse)
		{
			class VerbHandler
			{
				private 
				{
					string _verb;
					Route!(TRequest, TResponse)[string] _routes;
					public 
					{
						this(string normalizedVerb)
						{
							_verb = normalizedVerb;
						}

						@property string verb()
						{
							return _verb;
						}


						Route!(TRequest, TResponse) route(string path)
						{
							Route!(TRequest, TResponse) route = null;
							if (path in _routes)
							{
								route = _routes[path];
							}
							if (route is null)
							{
								route = (_routes[path] = new Route!(TRequest, TResponse)(path));
							}
							return route;
						}

						void execute(string path, TRequest request, TResponse response)
						{
							foreach (r; _routes)
							{
								r.execute(path, request, response);
							}
						}

					}
				}
			}
		}
		private template BootstrapVerb(string methodName)
		{
			const char[] BootstrapVerb = "EventList!(void, TRequest, TResponse) " ~ methodName.toLower ~ "(string path) { return this.map(\"" ~ methodName.toUpper ~ "\", path); }";

		}

		template Router(TRequest : IRoutedRequest, TResponse)
		{
			class Router
			{
				private 
				{
					VerbHandler!(TRequest, TResponse)[string] _verbs;
					VerbHandler!(TRequest, TResponse) _getVerb(string verb)
					{
						string normalizedVerb = verb.toUpper;
						VerbHandler!(TRequest, TResponse) handler = null;
						if (normalizedVerb in _verbs)
						{
							handler = _verbs[normalizedVerb];
						}
						if (handler is null)
						{
							handler = (_verbs[normalizedVerb] = new VerbHandler!(TRequest, TResponse)(normalizedVerb));
						}
						return handler;
					}

					public 
					{
						EventList!(void, TRequest, TResponse) map(string verb, string path)
						{
							auto handler = _getVerb(verb);
							return handler.route(path);
						}

						mixin(BootstrapVerb!"GET");
						mixin(BootstrapVerb!"HEAD");
						mixin(BootstrapVerb!"POST");
						mixin(BootstrapVerb!"PUT");
						void execute(string verb, string path, TRequest request, TResponse response)
						{
							auto handler = _getVerb(verb);
							handler.execute(path, request, response);
						}

					}
				}
			}
		}
	}
}
