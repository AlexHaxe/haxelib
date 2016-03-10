import haxe.crypto.Crc32;
import haxe.zip.Entry;
import haxe.zip.Writer;
import haxe.zip.Tools;

import sys.io.File;
import sys.FileSystem;

class Package {
    static var outPath = "package.zip";

    static function main() {
        var entries = new List<Entry>();

        function add(path:String, ?target:String) {
            if (!FileSystem.exists(path))
                throw 'Invalid path: $path';

            if (target == null)
                target = path;

            if (FileSystem.isDirectory(path)) {
                for (item in FileSystem.readDirectory(path))
                    add(path + "/" + item, target + "/" + item);
            } else {
                Sys.println("Adding " + target);
                var bytes = File.getBytes(path);
                var entry:Entry = {
                    fileName: target,
                    fileSize: bytes.length,
                    fileTime: FileSystem.stat(path).mtime,
                    compressed: false,
                    dataSize: 0,
                    data: bytes,
                    crc32: Crc32.make(bytes),
                }
                Tools.compress(entry, 9);
                entries.add(entry);
            }
        }

        for (file in FileSystem.readDirectory("src/haxelib"))
            if (file != "server")
                add('src/haxelib/$file');

        add("haxelib.json");
        add("README.md");

        // these are files provided for backward-compatibility, to make selfupdate work from old clients to the new version
        var compat = [
            {name: "src/tools/haxelib/Main.hx", content: "package tools.haxelib;class Main{static function main()@:privateAccess haxelib.client.Main.main();}"},
            {name: "src/tools/haxelib/Rebuild.hx", content: "package tools.haxelib;class Rebuild{static function main()@:privateAccess haxelib.client.Rebuild.main();}"},
        ];
        for (item in compat) {
            var bytes = haxe.io.Bytes.ofString(item.content);
            var entry:Entry = {
                fileName: item.name,
                fileSize: bytes.length,
                fileTime: Date.now(),
                compressed: false,
                dataSize: 0,
                data: bytes,
                crc32: Crc32.make(bytes)
            };
            Tools.compress(entry, 9);
            entries.add(entry);
        }

        Sys.println("Saving to " + outPath);
        var out = File.write(outPath, true);
        var writer = new Writer(out);
        writer.write(entries);
        out.close();
    }
}