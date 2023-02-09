// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

abstract contract OwnableLayout {

    address internal _owner;
    mapping(address => bool) internal _associatedOperators;

}