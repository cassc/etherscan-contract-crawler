// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

abstract contract Admin {

    mapping(address => bool) private _admin;


    function _isAdmin(address operator) internal view returns (bool) {
        return _admin[operator];
    }

    function _setAdmin(address operator, bool admin) internal {
        _admin[operator] = admin;
    }
}