package tink.http;

import haxe.io.Bytes;

import tink.io.*;
import tink.io.Sink;
import tink.core.Named;

using tink.io.Source;
using tink.CoreApi;

typedef StructuredBody = Array<Named<BodyPart>>;

enum BodyPart {
  Value(v:String);
  File(handle:UploadedFile);
}

@:forward
abstract UploadedFile(UploadedFileBase) from UploadedFileBase to UploadedFileBase {
  static public function ofBlob(name:String, type:String, data:Bytes):UploadedFile
    return {
      fileName: name,
      mimeType: type,
      size: data.length,
      read: function():RealSource return data,
      saveTo: function(path:String) {
        var name = 'File sink $path';
        var dest:RealSink = 
          #if (nodejs && !macro)
            Sink.ofNodeStream(name, js.node.Fs.createWriteStream(path))
          #elseif sys
            null //Sink.ofOutput(name, sys.io.File.write(path))
          #else
            throw 'not implemented'
          #end
        ;
        return (data : IdealSource).pipeTo(dest, { end: true } ).map(function (r) return switch r {
          case AllWritten: Success(Noise);
          case SinkEnded(_, _): Failure(new Error("File $path closed unexpectedly"));
          case SinkFailed(e, _): Failure(e);
        });
      }
    }
}

typedef UploadedFileBase = {
  
  var fileName(default, null):String;
  var mimeType(default, null):String;
  var size(default, null):Int;
  
  function read():RealSource;
  function saveTo(path:String):Surprise<Noise, Error>;
}