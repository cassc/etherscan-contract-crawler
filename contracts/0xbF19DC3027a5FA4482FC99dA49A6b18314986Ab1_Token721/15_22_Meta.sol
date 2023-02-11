//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '../Polly.sol';
import '../PollyConfigurator.sol';
import './Json.sol';


contract Meta is PMClone {

  Json private _json_parser;
  string public constant override PMNAME = 'Meta';
  uint public constant override PMVERSION = 1;

  struct Item {
    Json.Type _type;
    string _key;
    string _inject;
  }

  mapping(uint => mapping(string => Polly.Param)) private _keys;
  mapping(uint => mapping(string => bool)) private _locked_id_keys;
  mapping(string => bool) private _locked_keys;
  mapping(uint => bool) private _locked_ids;

  modifier onlyManager() {
    require(hasRole('manager', msg.sender), 'ONLY_MANAGER');
    _;
  }

  constructor() PMClone(){
    _setConfigurator(address(new MetaConfigurator()));
  }

  function setJsonParser(address json_parser) public onlyManager {
    _json_parser = Json(json_parser);
  }

  function _reqValidKeyID(uint id_, string memory key_) private view {
    require(!isLockedId(id_), string(abi.encodePacked('ID_KEY_LOCKED', Strings.toString(id_))));
    require(!isLockedKey(key_), string(abi.encodePacked('KEY_LOCKED', key_)));
    require(!isLockedIdKey(id_, key_), string(abi.encodePacked('KEY_LOCKED', Strings.toString(id_), ':', key_)));
  }



  /// JSON
  function getJSON(uint id_, Item[] memory items_, Json.Format format_) public view returns (string memory) {

    Json.Item[] memory json_items_ = new Json.Item[](items_.length);
    Item memory item;

    for (uint i = 0; i < items_.length; i++) {

      item = items_[i];

      json_items_[i]._key = item._key;
      json_items_[i]._type = item._type;

      if(item._type == Json.Type.ARRAY || item._type == Json.Type.OBJECT) {
        json_items_[i]._string = item._inject;
      } else if (item._type == Json.Type.STRING) {
        json_items_[i]._string = _keys[id_][item._key]._string;
      } else if (item._type == Json.Type.BOOL) {
        json_items_[i]._bool = _keys[id_][item._key]._bool;
      } else if (item._type == Json.Type.NUMBER) {
        json_items_[i]._uint = _keys[id_][item._key]._uint;
      }

    }

    string memory json_ = _json_parser.encode(json_items_, format_);

    return string(json_);

  }

  function _getKeyJson(string memory key_) private pure returns(string memory){
    return string(abi.encodePacked('"', key_,'":'));
  }


  /// Access
  function lockKey(string memory key_) public onlyManager {
    _locked_keys[key_] = true;
  }

  function lockId(uint id_) public onlyManager {
    _locked_ids[id_] = true;
  }

  function lockIdKey(uint id_, string memory key_) public onlyManager {
    _locked_id_keys[id_][key_] = true;
  }

  function isLockedKey(string memory key_) public view returns (bool) {
    return _locked_keys[key_];
  }

  function isLockedId(uint id_) public view returns (bool) {
    return _locked_ids[id_];
  }

  function isLockedIdKey(uint id_, string memory key_) public view returns (bool) {
    return _locked_id_keys[id_][key_];
  }

  function isLocked(uint id_, string memory key_) public view returns (bool) {
    return isLockedKey(key_) || isLockedId(id_) || isLockedIdKey(id_, key_);
  }


  /// Setters
  function set(uint id_, string memory key_, Polly.Param memory value_) public onlyManager {
    _reqValidKeyID(id_, key_);
    _keys[id_][key_]._string = value_._string;
    _keys[id_][key_]._uint = value_._uint;
    _keys[id_][key_]._int = value_._int;
    _keys[id_][key_]._bool = value_._bool;
    _keys[id_][key_]._address = value_._address;
  }

  function setString(uint id_, string memory key_, string memory value_) public onlyManager {
    _reqValidKeyID(id_, key_);
    _keys[id_][key_]._string = value_;
  }

  function setUint(uint id_, string memory key_, uint value_) public onlyManager {
    _reqValidKeyID(id_, key_);
    _keys[id_][key_]._uint = value_;
  }

  function setInt(uint id_, string memory key_, int value_) public onlyManager {
    _reqValidKeyID(id_, key_);
    _keys[id_][key_]._int = value_;
  }

  function setBool(uint id_, string memory key_, bool value_) public onlyManager {
    _reqValidKeyID(id_, key_);
    _keys[id_][key_]._bool = value_;
  }

  function setAddress(uint id_, string memory key_, address value_) public onlyManager {
    _reqValidKeyID(id_, key_);
    _keys[id_][key_]._address = value_;
  }

  function wipeKey(uint id_, string memory key_) public onlyManager {
    _reqValidKeyID(id_, key_);
    delete _keys[id_][key_];
  }



  /// Getters

  /// @dev Get a key param value
  /// @param id_ The id of the param
  /// @param key_ The key of the param
  /// @return The param value
  function get(uint id_, string memory key_) public view returns (Polly.Param memory) {
    return _keys[id_][key_];
  }

  /// @dev a function to retrieve a string value from a key
  /// @param id_ the id of the key
  /// @param key_ the key to retrieve
  /// @return the value of the key
  function getString(uint id_, string memory key_) public view returns (string memory) {
    return _keys[id_][key_]._string;
  }

  /// @dev a function to retrieve a uint value from a key
  /// @param id_ the id of the key
  /// @param key_ the key to retrieve
  /// @return the value of the key
  function getUint(uint id_, string memory key_) public view returns (uint) {
    return _keys[id_][key_]._uint;
  }

  /// @dev a function to retrieve a int value from a key
  /// @param id_ the id of the key
  /// @param key_ the key to retrieve
  /// @return the value of the key
  function getInt(uint id_, string memory key_) public view returns (int) {
    return _keys[id_][key_]._int;
  }

  /// @dev a function to retrieve a bool value from a key
  /// @param id_ the id of the key
  /// @param key_ the key to retrieve
  /// @return the value of the key
  function getBool(uint id_, string memory key_) public view returns (bool) {
    return _keys[id_][key_]._bool;
  }

  /// @dev a function to retrieve a address value from a key
  /// @param id_ the id of the key
  /// @param key_ the key to retrieve
  /// @return the value of the key
  function getAddress(uint id_, string memory key_) public view returns (address) {
    return _keys[id_][key_]._address;
  }


  function getBatchForId(uint id_, string[] memory keys_) public view returns (Polly.Param[] memory) {
    Polly.Param[] memory params_ = new Polly.Param[](keys_.length);
    for (uint i = 0; i < keys_.length; i++) {
      params_[i] = _keys[id_][keys_[i]];
    }
    return params_;
  }

  function setBatchForId(uint id_, string[] memory keys_, Polly.Param[] memory values_) public onlyManager {
    require(keys_.length == values_.length, "KEY_VALUE_LENGHT_MISMATCH");
    for (uint i = 0; i < keys_.length; i++) {
      _reqValidKeyID(id_, keys_[i]);
      _keys[id_][keys_[i]] = values_[i];
    }
  }

}


contract MetaConfigurator is PollyConfigurator {

  function outputs() public pure override returns (string[] memory) {

    string[] memory outputs_ = new string[](1);
    outputs_[0] = "module || Meta || address of the Meta module clone";

    return outputs_;

  }

  function run(Polly polly_, address for_, Polly.Param[] memory) public override payable returns(Polly.Param[] memory){

    // Clone a Meta module)
    Meta meta_ = Meta(polly_.cloneModule('Meta', 1));

    // Set the json module to use
    meta_.setJsonParser(polly_.getModule('Json', 1).implementation);

    // Grant roles to the address calling the configurator
    _transfer(address(meta_), for_);

    // Return the cloned module as part of the return parameters
    Polly.Param[] memory return_ = new Polly.Param[](1);
    return_[0]._string = 'Meta';
    return_[0]._address = address(meta_); // The address of newly cloned and configured meta module
    return_[0]._uint = 1; // The version of the module

    return return_;

  }


}