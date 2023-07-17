// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

contract Configurable {
    mapping (bytes32 => uint) internal _config;

    function getConfig(bytes32 key) public view returns (uint) {
        return _config[key];
    }
    function getConfig(bytes32 key, uint index) public view returns (uint) {
        return _config[bytes32(uint(key) ^ index)];
    }
    function getConfig(bytes32 key, address addr) public view returns (uint) {
        return _config[bytes32(uint(key) ^ uint(addr))];
    }

    function _setConfig(bytes32 key, uint value) internal {
        if(_config[key] != value)
            _config[key] = value;
    }

    function _setConfig(bytes32 key, uint index, uint value) internal {
        _setConfig(bytes32(uint(key) ^ index), value);
    }

    function _setConfig(bytes32 key, address addr, uint value) internal {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
}