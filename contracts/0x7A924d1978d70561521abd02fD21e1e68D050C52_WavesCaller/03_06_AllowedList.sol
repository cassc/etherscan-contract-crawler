// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Adminable.sol";

abstract contract AllowedList is Adminable {
    mapping(address => bool) public allowance;

    function allow(address caller_) external onlyAdmin {
        allowance[caller_] = true;
    }

    function disallow(address caller_) external onlyAdmin {
        allowance[caller_] = false;
    }

    modifier whenAllowed(address member) {
        require(allowance[member], "not allowed");
        _;
    }
}