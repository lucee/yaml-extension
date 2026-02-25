<!--- 
*
* Copyright (c) 2026, Lucee Association Switzerland. All rights reserved.
*
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either 
* version 2.1 of the License, or (at your option) any later version.
* 
* This library is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* Lesser General Public License for more details.
* 
* You should have received a copy of the GNU Lesser General Public 
* License along with this library.  If not, see <http://www.gnu.org/licenses/>.
* 
---><cfscript>
component extends="org.lucee.cfml.test.LuceeTestCase" labels="yaml" {

    
    variables.testDir = "";

    function beforeAll() {
        variables.testDir = expandPath("{temp}") & "/yaml-test-" & createUUID();
        directoryCreate(variables.testDir);
    }

    function afterAll() {
        if (directoryExists(variables.testDir))
            directoryDelete(variables.testDir, true);
    }

    function run(testResults, testBox) {


        // -------------------------------------------------------------------------
        describe("check correctly installed", function() {

            it("does the component exist?", function() {
                var components=ComponentListPackage("org.lucee.cfml.tools");
                expect(arrayContains(components,"Yaml")>0).toBeTrue();
            });
            it("global javasettings are okay?", function() {
                systemOutput("Global Java Settings: " ,1,1);
                    js=getPageContext().getConfig().getJavaSettings();
                    var hasJar=false;
                    loop collection=js.getAllResources() index="i" item="res" {
                        if (findNoCase("snakeyaml", res&"") > 0) {
                            hasJar = true;
                        }
                    }
                    expect(hasJar).toBeTrue();
            });
        });

        // -------------------------------------------------------------------------
        describe("parse / serialize", function() {

            it("parses a simple struct from a YAML string", function() {
                var yaml    = new cfml:org.lucee.cfml.tools.Yaml();
                var result = yaml.parse("name: Lucee#chr(10)#version: 7");
                expect(result.name).toBe("Lucee");
                expect(result.version).toBe(7);
            });

            it("parses a nested struct", function() {
                var yaml    = new cfml:org.lucee.cfml.tools.Yaml();
                var result = yaml.parse("
server:
  host: localhost
  port: 8080
");
                expect(result.server.host).toBe("localhost");
                expect(result.server.port).toBe(8080);
            });

            it("parses a YAML array", function() {
                var yaml    = new cfml:org.lucee.cfml.tools.Yaml();
                var result = yaml.parse("items:#chr(10)#  - one#chr(10)#  - two#chr(10)#  - three");
                expect(result.items.len()).toBe(3);
                expect(result.items[2]).toBe("two");
            });

            it("round-trips a struct through serialize and parse", function() {
                var yaml    = new cfml:org.lucee.cfml.tools.Yaml();
                var data   = { name: "Lucee", active: true, count: 42 };
                var result = yaml.parse(yaml.serialize(data));
                expect(result.name).toBe("Lucee");
                expect(result.active).toBe(true);
                expect(result.count).toBe(42);
            });
        });

        // -------------------------------------------------------------------------
        describe("read / write", function() {

            it("writes a YAML file and reads it back", function() {
                var yaml    = new cfml:org.lucee.cfml.tools.Yaml();
                var filePath = variables.testDir & "/config.yaml";
                yaml.write({ environment: "production", debug: false }, filePath);
                expect(fileExists(filePath)).toBeTrue();
                var result = yaml.read(filePath);
                expect(result.environment).toBe("production");
                expect(result.debug).toBe(false);
            });

            it("throws when reading a missing file", function() {
                var yaml    = new cfml:org.lucee.cfml.tools.Yaml();
                expect(function() {
                    yaml.read(variables.testDir & "/does-not-exist.yaml");
                }).toThrow();
            });
        });

        // -------------------------------------------------------------------------
        describe("multi-document", function() {

            it("parses multiple documents from a YAML string", function() {
                var yaml    = new cfml:org.lucee.cfml.tools.Yaml();
                var result = yaml.parseAll("name: doc1#chr(10)#---#chr(10)#name: doc2");
                expect(result.len()).toBe(2);
                expect(result[1].name).toBe("doc1");
                expect(result[2].name).toBe("doc2");
            });

            it("reads multiple documents from a YAML file", function() {
                var yaml    = new cfml:org.lucee.cfml.tools.Yaml();
                var filePath = variables.testDir & "/multi.yaml";
                fileWrite(filePath, "name: doc1#chr(10)#---#chr(10)#name: doc2");
                var result = yaml.readAll(filePath);
                expect(result.len()).toBe(2);
                expect(result[2].name).toBe("doc2");
            });
        });

        // -------------------------------------------------------------------------
        describe("validate", function() {

            it("returns true for valid YAML", function() {
                var yaml    = new cfml:org.lucee.cfml.tools.Yaml();
                expect(yaml.validate("name: Lucee")).toBeTrue();
            });

            it("returns false for invalid YAML", function() {
                var yaml    = new cfml:org.lucee.cfml.tools.Yaml();
                expect(yaml.validate("key: [unclosed")).toBeFalse();
            });

            it("throws for invalid YAML when throwOnInvalid is true", function() {
                var yaml    = new cfml:org.lucee.cfml.tools.Yaml();
                expect(function() {
                    yaml.validate("key: [unclosed", true);
                }).toThrow(type="YAMLTool.InvalidYAML");
            });
        });
    }
}
</cfscript>