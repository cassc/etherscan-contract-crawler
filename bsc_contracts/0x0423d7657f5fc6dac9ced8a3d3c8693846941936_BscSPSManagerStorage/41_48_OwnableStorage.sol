// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableLayout.sol";

//this is a leaf module
contract OwnableStorage is OwnableLayout {

    constructor (address owner_) {
        _owner = owner_;
    }
}