// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;
pragma abicoder v2;

import '../core/SafeOwnable.sol';

contract ConfigView is SafeOwnable {

    mapping(string => string[]) public configs;

    function addConfig(string memory _key, string[] memory _values) external onlyOwner {
        configs[_key] = _values;
    }

    function setConfig(string memory _key, uint _index, string memory _value) external onlyOwner {
        for (uint i = configs[_key].length; i <= _index; i ++) {
            configs[_key].push("");
        }
        configs[_key][_index] = _value;
    }

    function getConfig(string memory _key) external view returns (string[] memory) {
        return configs[_key];
    }

    function existConfig(string memory _key) external view returns (bool) {
        return configs[_key].length > 0;
    }
}