// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Configurable is OwnableUpgradeable {

    mapping (bytes32 => uint256) internal config;
    
    function getConfig(bytes32 key) public view returns (uint256) {
        return config[key];
    }
    function getConfig(bytes32 key, uint256 index) public view returns (uint256) {
        return config[bytes32(uint256(key) ^ index)];
    }
    function getConfig(bytes32 key, address addr) public view returns (uint256) {
        return config[bytes32(uint256(key) ^ uint256(uint160(addr)))];
    }

    function _setConfig(bytes32 key, uint256 value) internal {
        if(config[key] != value)
            config[key] = value;
    }

    function _setConfig(bytes32 key, uint256 index, uint256 value) internal {
        _setConfig(bytes32(uint256(key) ^ index), value);
    }

    function _setConfig(bytes32 key, address addr, uint256 value) internal {
        _setConfig(bytes32(uint256(key) ^ uint256(uint160(addr))), value);
    }
    
    function setConfig(bytes32 key, uint256 value) external onlyOwner {
        _setConfig(key, value);
    }

    function setConfig(bytes32 key, uint256 index, uint256 value) external onlyOwner {
        _setConfig(bytes32(uint256(key) ^ index), value);
    }
    
    function setConfig(bytes32 key, address addr, uint256 value) public onlyOwner {
        _setConfig(bytes32(uint256(key) ^ uint256(uint160(addr))), value);
    }
}