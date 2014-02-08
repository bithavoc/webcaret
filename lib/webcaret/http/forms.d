module webcaret.http.forms;
import std.string : translate;
import std.array : split;
import std.uri : decodeComponent;

alias string[string] FormFields;

private:

static dchar[dchar] FormDecodingTranslation;

static this() {
    FormDecodingTranslation = ['+' : ' '];
}

string decodeFormComponent(string component) {
    return component.translate(FormDecodingTranslation);
}

public:

FormFields parseURLEncodedForm(string content) {
    if(content.length < 1) return null;
    FormFields fields;
    string[] pairs = content.split("&");
    foreach(entry; pairs) {
        string[] values = entry.split("=");
        string name = values[0].decodeComponent.decodeFormComponent;
        string value = values[1];
        fields[name] = value.decodeComponent.decodeFormComponent;
    }
    return fields;
}
