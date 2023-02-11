//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '../Polly.sol';

contract Json is PMReadOnly {

  enum Type {
    STRING, BOOL, NUMBER, OBJECT, ARRAY
  }

  enum Format {
    KEY_VALUE, VALUE, ARRAY, OBJECT
  }

  struct Item {
    Type _type;
    string _key;
    string _string;
    bool _bool;
    uint _uint;
  }

  string public constant override PMNAME = 'Json';
  uint public constant override PMVERSION = 1;

  function encode(Item[] memory items_, Format format_) public pure returns(string memory){

      bytes[] memory parts_ = new bytes[](items_.length);
      bytes memory append_ = ',';
      bool include_key_;

      for (uint i = 0; i < items_.length; i++) {

        Item memory item = items_[i];

        if(i+1 == items_.length) {
          append_ = '';
        }

        if((format_ == Format.OBJECT || format_ == Format.KEY_VALUE))
          include_key_ = true;
        else
          include_key_ = false;

        if (item._type == Type.OBJECT || item._type == Type.ARRAY) {
          parts_[i] = abi.encodePacked(include_key_ ? _getKeyJson(item._key) : '', item._string, append_);
        } else if (item._type == Type.STRING) {
          parts_[i] = abi.encodePacked(include_key_ ? _getKeyJson(item._key) : '', '"', item._string, '"', append_);
        } else if (item._type == Type.BOOL) {
          parts_[i] = abi.encodePacked(include_key_ ? _getKeyJson(item._key) : '', item._bool ? 'true' : 'false', append_);
        } else if (item._type == Type.NUMBER) {
          parts_[i] = abi.encodePacked(include_key_ ? _getKeyJson(item._key) : '', Strings.toString(item._uint), append_);
        }

      }

      bytes memory open_;
      bytes memory close_;

      if(format_ == Format.ARRAY){
        open_ = '[';
        close_ = ']';
      }
      else if(format_ == Format.OBJECT){
        open_ = '{';
        close_ = '}';
      }

      bytes memory json_;
      for (uint i = 0; i < parts_.length; i++) {
        json_ = abi.encodePacked(json_, parts_[i]);
      }
      json_ = abi.encodePacked(open_, json_, close_);

      return string(json_);
  }


  function _getKeyJson(string memory key_) private pure returns(string memory){
    return string(abi.encodePacked('"', key_,'":'));
  }

}