// D import file generated from 'lib/events.d'
module events;
import std.algorithm;
import std.container;
import std.string;
import std.range;
import core.thread : Fiber;
enum EventOperation 
{
	Unknown,
	Added,
	Removed,
}
abstract template Event(TReturn, Args...)
{
	class Event
	{
		alias TReturn delegate(Args) delegateType;
		protected 
		{
			abstract void add(delegateType item);


			public 
			{
				void addSync(delegateType item)
				{
					this.add(item);
				}

				void addAsync(delegateType item)
				{
					auto fibered = delegate TReturn(Args args)
					{
						static if (is(TReturn == void))
						{
							Fiber fiber = new Fiber(()
							{
								item(args);
							}
							);
							fiber.call;
						}
						else
						{
							TReturn v;
							Fiber fiber = new Fiber(()
							{
								v = item(args);
							}
							);
							fiber.call;
							return v;
						}

					}
					;
					this.add(fibered);
				}

			}
		}
	}
}

template Action(TReturn, Args...)
{
	class Action : Event!(TReturn, Args)
	{
		alias TReturn delegate(Args) delegateType;
		alias void delegate(delegateType) handlerType;
		private 
		{
			handlerType _handler;
			protected 
			{
				override void add(delegateType item)
				{
					_handler(item);
				}


				public 
				{
					this(handlerType handler)
					{
						_handler = handler;
					}

					template opBinary(string op)
					{
						auto opBinary(delegateType rhs)
						{
							static if (op == "^")
							{
								static assert(0, "Operator ^ is only valid for events, use ^= instead");
							}
							else
							{
								static if (op == "^^")
								{
									static assert(0, "Operator ^^ is only valid for events, use ^^= instead");
								}
								else
								{
									static assert(0, "Operator " ~ op ~ " not implemented");
								}

							}

							return this;
						}

					}
					template opOpAssign(string op)
					{
						auto opOpAssign(delegateType rhs)
						{
							static if (op == "^")
							{
								this.add(rhs);
							}
							else
							{
								static if (op == "^^")
								{
									this.addAsync(rhs);
								}
								else
								{
									static assert(0, "Operator " ~ op ~ " not implemented");
								}

							}

							return this;
						}

					}
				}
			}
		}
	}
}
template EventList(TReturn, Args...)
{
	class EventList : Event!(TReturn, Args)
	{
		alias void delegate(Trigger trigger, bool activated) activationDelegate;
		private 
		{
			delegateType[] _list;
			Trigger _trigger;
			protected 
			{
				final override void add(delegateType item)
				{
					auto oldCount = normalizedCount;
					onAdd(item, oldCount);
				}


				public 
				{
					final void remove(delegateType item)
					{
						auto oldCount = normalizedCount;
						onRemove(item, oldCount);
					}


					@property bool active()
					{
						return normalizedCount != 0;
					}


					final class Trigger
					{
						package 
						{
							this()
							{
							}

							public 
							{
								void delegate(EventOperation operation, delegateType item) changed;
								activationDelegate activation;
								auto opCall(Args args)
								{
									return execute(args);
								}

								auto execute(Args args)
								{
									static if (is(TReturn == void))
									{
										foreach (d; _list)
										{
											this.outer.onExecute(d, args);
										}
									}
									else
									{
										TReturn v;
										foreach (d; _list)
										{
											v = this.outer.onExecute(d, args);
										}
										return v;
									}

								}

								@property size_t count()
								{
									return _list.length;
								}


								void reset()
								{
									foreach (d; _list)
									{
										remove(d);
									}
								}

							}
						}
					}

					auto own()
					{
						return this.own(null);
					}

					auto own(activationDelegate activation)
					{
						if (_trigger !is null)
						{
							throw new Exception("Event already owned");
						}
						_trigger = new Trigger;
						_trigger.activation = activation;
						return _trigger;
					}

					template opOpAssign(string op)
					{
						auto opOpAssign(delegateType rhs)
						{
							static if (op == "^")
							{
								static assert(0, "Operator ^= is only valid for actions, use ^ instead");
							}
							else
							{
								static if (op == "^^")
								{
									static assert(0, "Operator ^^= is only valid for actions, use ^^ instead");
								}
								else
								{
									static assert(0, "Operator " ~ op ~ " not implemented");
								}

							}

							return this;
						}

					}
					template opBinary(string op)
					{
						auto opBinary(delegateType rhs)
						{
							static if (op == "^")
							{
								this.add(rhs);
							}
							else
							{
								static if (op == "^^")
								{
									this.addAsync(rhs);
								}
								else
								{
									static assert(0, "Operator " ~ op ~ " not implemented");
								}

							}

							return this;
						}

					}
					protected 
					{
						TReturn onExecute(delegateType item, Args args)
						{
							return item(args);
						}

						void onAdd(delegateType item, size_t oldCount)
						{
							_list ~= item;
							this.onChanged(EventOperation.Added, item, oldCount);
						}

						void onRemove(delegateType item, size_t oldCount)
						{
							import std.algorithm : countUntil, remove;
							auto i = _list.countUntil(item);
							if (i > -1)
							{
								_list = _list.remove(i);
							}
							this.onChanged(EventOperation.Removed, item, oldCount);
						}

						@property size_t normalizedCount()
						{
							return _trigger !is null ? _trigger.count : 0;
						}


						void onChanged(EventOperation operation, delegateType item, size_t oldCount)
						{
							if (_trigger !is null)
							{
								if (_trigger.changed)
								{
									_trigger.changed(operation, item);
								}
								auto subscriptionCount = normalizedCount;
								if (_trigger.activation !is null && (oldCount == 0 && subscriptionCount == 1 || oldCount == 1 && subscriptionCount == 0))
								{
									_trigger.activation(_trigger, this.active);
								}
							}
						}

					}
				}
			}
		}
	}
}
enum StrictTrigger 
{
	Sync = "Sync",
	Async = "Async",
}
template StrictEventList(StrictTrigger style, TReturn, Args...)
{
	class StrictEventList : EventList!(TReturn, Args)
	{
		public 
		{
			template opBinary(string op)
			{
				auto opBinary(delegateType rhs)
				{
					static if (op == "^")
					{
						static if (style == StrictTrigger.Async)
						{
							static assert(0, "Operator ^ is disallowed in strictly Async events, use ^^ instead for an async subscription");
						}
						else
						{
							super.opBinary!op(rhs);
						}

					}
					else
					{
						static if (op == "^^")
						{
							static if (style == StrictTrigger.Sync)
							{
								static assert(0, "Operator ^^ is disallowed in strictly Sync events, use ^ instead for a sync subscription");
							}
							else
							{
								super.opBinary!op(rhs);
							}

						}
						else
						{
							static assert(0, "Operator " ~ op ~ " not implemented");
						}

					}

					return this;
				}

			}
			static if (style == StrictTrigger.Sync)
			{
				final override @disable void addAsync(delegateType item)
				{
					assert(0, "addAsync is disallowed in strictly Sync events, use addSync instead for a sync subscription");
				}


			}
			static if (style == StrictTrigger.Async)
			{
				final override @disable void addSync(delegateType item)
				{
					assert(0, "addSync is disallowed in strictly Async events, use addAsync instead for a async subscription");
				}


			}
		}
	}
}
template StrictAction(StrictTrigger style, TReturn, Args...)
{
	class StrictAction : Action!(TReturn, Args)
	{
		public 
		{
			this(handlerType handler)
			{
				super(handler);
			}

			template opOpAssign(string op)
			{
				auto opOpAssign(delegateType rhs)
				{
					static if (op == "^")
					{
						static if (style == StrictTrigger.Async)
						{
							static assert(0, "Operator ^= is disallowed in strictly Async actions, use ^^= instead for an async subscription");
						}
						else
						{
							super.opOpAssign!op(rhs);
						}

					}
					else
					{
						static if (op == "^^")
						{
							static if (style == StrictTrigger.Sync)
							{
								static assert(0, "Operator ^^= is disallowed in strictly Sync actions, use ^= instead for a sync subscription");
							}
							else
							{
								super.opOpAssign!op(rhs);
							}

						}
						else
						{
							static assert(0, "Operator " ~ op ~ " not implemented");
						}

					}

					return this;
				}

			}
			static if (style == StrictTrigger.Sync)
			{
				final override @disable void addAsync(delegateType item)
				{
					assert(0, "addAsync is disallowed in strictly Sync actions, use addSync instead for a sync subscription");
				}


			}
			static if (style == StrictTrigger.Async)
			{
				final override @disable void addSync(delegateType item)
				{
					assert(0, "addSync is disallowed in strictly Async actions, use addAsync instead for a async subscription");
				}


			}
		}
	}
}
