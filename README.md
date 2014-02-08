webcaret
========

Web^ is the first Web Framework for the upcoming Heaploop platform



Sneak Peek
-----------

```d
import webcaret.application;
import heaploop.looping;

void main() {
    loop ^^ {
        auto app = new Application;
        app.router.get("/") ^ (req, res) {
            res.write("Hello World");
            res.end;
        };
        app.serve("0.0.0.0", 3000);
    };
}
```
