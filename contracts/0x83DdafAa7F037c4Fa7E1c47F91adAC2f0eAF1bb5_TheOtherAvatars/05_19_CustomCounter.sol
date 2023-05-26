// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract CustomCounter {
    uint256 private _value;
    
    constructor(uint256 defaultValue_) {
        _value = defaultValue_;
    }

    function counterCurrent() internal view returns (uint256) {
        return _value;
    }

    function counterIncrement() internal {
        unchecked {
            _value += 1;
        }
    }
}