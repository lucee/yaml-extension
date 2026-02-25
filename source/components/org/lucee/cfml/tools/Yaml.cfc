/**
 * requires SnakeYAML library in javasettings (e.g. {mvnGroupId}:{mvnArtifactId}:{mvnVersion}) to use this component
 */
component
    displayname="{label}"
    description="{description}"
    javasettings='{"maven":["{mvnGroupId}:{mvnArtifactId}:{mvnVersion}"]}' {

    import org.yaml.snakeyaml.*;
    import org.yaml.snakeyaml.DumperOptions;
    import java.io.FileInputStream;
    import java.io.StringReader;
	import lucee.runtime.java.JavaProxy;

    // reuse a single Yaml instance configured for pretty output
    variables.yaml = nullValue();

    private function getYaml() {
        if (isNull(variables.yaml)) {
            var options = new java:DumperOptions();	
			options.setPrettyFlow(true);
            options.setIndent(2);
            variables.yaml = new java:Yaml(options);
        }
        return variables.yaml;
    }

    /**
     * Read a YAML file and return it as a CFML struct/array
     */
    function read(required string filePath) {
        try {
            var inputStream = new FileInputStream(expandPath(arguments.filePath));
            return JavaProxy::toCFML(getYaml().load(inputStream));
        }
        finally {
            if (!isNull(inputStream)) inputStream.close();
        }
    }

    /**
     * Write a CFML struct/array to a YAML file
     */
    function write(required any data, required string filePath) {
		fileWrite(arguments.filePath, serialize(arguments.data));
    }

    /**
     * Parse a YAML string and return it as a CFML struct/array
     */
    function parse(required string yamlString) {
        return JavaProxy::toCFML(getYaml().load(arguments.yamlString));
    }

    /**
     * Serialize a CFML struct/array to a YAML string
     */
    function serialize(required any data) {
		return getYaml().dump(arguments.data);
    }

    /**
     * Parse a YAML string that contains multiple documents (separated by ---)
     * Returns an array of structs/arrays, one per document
     */
    function parseAll(required string yamlString) {
        var results = [];
        var docs = getYaml().loadAll(arguments.yamlString);
        var iter = docs.iterator();
        while (iter.hasNext()) {
            results.append(JavaProxy::toCFML(iter.next()));
        }
        return results;
    }

    /**
     * Read a YAML file that contains multiple documents
     */
    function readAll(required string filePath) {
        var inputStream = null;
        try {
            inputStream = new FileInputStream(arguments.filePath);
            var results = [];
            var docs = getYaml().loadAll(inputStream);
            var iter = docs.iterator();
            while (iter.hasNext()) {
                results.append(iter.next());
            }
            return results;
        }
        finally {
            if (!isNull(inputStream)) inputStream.close();
        }
    }

    /**
     * Validate that a string is well-formed YAML
     * Returns true/false, optionally throws with detail on invalid
     */
    function validate(required string yamlString, boolean throwOnInvalid=false) {
        try {
            getYaml().load(arguments.yamlString);
            return true;
        }
        catch (any e) {
            if (arguments.throwOnInvalid) {
                throw(
                    type    = "YAMLTool.InvalidYAML",
                    message = "Invalid YAML: #e.message#",
                    detail  = e.detail
                );
            }
            return false;
        }
    }
}