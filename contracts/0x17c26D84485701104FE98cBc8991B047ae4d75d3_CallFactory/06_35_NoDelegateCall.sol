// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

abstract contract NoDelegateCall {
    address private immutable selfAddress;

    constructor() {
        selfAddress = address(this);
    }

    modifier noDelegateCall() {
        require(address(this) == selfAddress);
        _;
    }
}