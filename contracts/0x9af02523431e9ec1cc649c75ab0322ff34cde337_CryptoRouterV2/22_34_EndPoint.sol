// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "./utils/Typecast.sol";


contract EndPoint is Typecast {

    /// @dev version
    string public version;
    /// @dev clp address book
    address public addressBook;

    constructor (address addressBook_) {
        version = "2.2.3";
        _checkAddress(addressBook_);
        addressBook = addressBook_;
    }

    function _setAddressBook(address addressBook_) internal {
        _checkAddress(addressBook_);
        addressBook = addressBook_;
    }

    function _checkAddress(address checkingAddress) private pure {
        require(checkingAddress != address(0), "EndPoint: zero address");
    }
}