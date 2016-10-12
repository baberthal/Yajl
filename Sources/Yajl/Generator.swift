//
//  Generator.swift
//  Yajl
//
//  Created by Morgan Lieberthal on 10/11/16.
//
//

import CYajl
import Foundation

/// JSON Generator
///
/// The generator supports the following types:
///   - `Array`
///   - `Dictionary`
///   - `String`
///   - `Int`
///   - `Double`
///   - `nil`
///
/// Additionally, the generator supports any type that conforms to 
/// the `JSONSerializable` protocol.
public class YajlGenerator {
  // MARK: - Public
  
  /// Options for JSON generation 
  public let options: Options

  /// An indent string to be used when generating JSON. This string is only
  /// used if `options` contains .beautify
  public let indentString: String

  /// The buffer that we are writing to.
  public var buffer: Data {
    var len: Int = 0
    var buf: UnsafePointer<UInt8>?
    let status = yajl_gen_get_buf(self.handle, &buf, &len)

    guard status == yajl_gen_status_ok, buf != nil else { return Data() }

    return Data(bytes: UnsafeMutableRawPointer(mutating: buf!), count: len)
  }

  // MARK: - Private

  /// The handle of the `yajl_gen` we are using
  private var handle: yajl_gen!

  // MARK: - Initializers

  /// Create a YajlGenerator, given `options` and an `indentString`
  ///
  /// - parameter options: `Options` for json generation
  /// - parameter indentString: The string to be used as an 'indent' when
  ///   `options` contains `.beautify`
  public init(options: Options = .none, indentString: String = "") {
    self.options = options
    self.indentString = indentString
    self.handle = yajl_gen_alloc(nil)
  }

  deinit {
    if self.handle != nil {
      yajl_gen_free(self.handle)
      self.handle = nil
    }
  }

  /// Write an object's JSON representation to the buffer.
  /// 
  /// - parameter object: The object to serialize as JSON.
  /// - precondition: `object` is of type JSONRepresentable
  public func write(object: JSONRepresentable) {
    func genArray(_ contents: [JSONRepresentable]) {
      startArray()
      for element in contents {
        write(object: element)
      }
      endArray()
    }

    func genDict(_ contents: [String: JSONRepresentable]) {
      startDict()
      for key in contents.keys.sorted() {
        write(object: .string(key))
        write(object: contents[key]!)
      }
      endDict()
    }

    switch object {
    case .null:            yajl_gen_null(handle)
    case .bool(let val):   yajl_gen_bool(handle, val ? 1 : 0)
    case .int(let val):    yajl_gen_integer(handle, Int64(val))
    case .double(let val): yajl_gen_double(handle, val)
    case .string(let val): yajl_gen_string(handle, val, val.lengthOfBytes(using: .utf8))
    case .array(let vals): genArray(vals)
    case .dict(let kvps):  genDict(kvps)
    }
  }

  /// Write an object's JSON representation to the buffer.
  ///
  /// - parameter object: The object to serialize as JSON.
  /// - precondition: `object` conforms to `JSONSerializable`
  public func write(object: JSONSerializable) {
    write(object: object.toJSON())
  }

  /// Write a dictionary start (`{`) to the buffer
  public func startDict() { yajl_gen_map_open(handle) }

  /// Write a dictionary end (`}`) to the buffer
  public func endDict() { yajl_gen_map_close(handle) }

  /// Write an array start (`[`) to the buffer
  public func startArray() { yajl_gen_array_open(handle) }

  /// Write an array end (`]`) to the buffer
  public func endArray() { yajl_gen_array_close(handle) }

  /// Reset the buffer to its initial state
  public func resetBuffer() {
    yajl_gen_clear(self.handle)
  }
}
