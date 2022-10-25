// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.7.0 <0.9.0;

import {IOwnedUninitialized} from "./IOwnedUninitialized.sol";

abstract contract OwnedUninitialized is IOwnedUninitialized {
    /// @inheritdoc IOwnedUninitialized
    address public override owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "OWNED_CALLER_IS_NOT_OWNER_ERROR");
        _;
    }

    /// @inheritdoc IOwnedUninitialized
    function setOwner(address newOwner) public override onlyOwner {
        require(newOwner != address(0));
        address oldOWner = newOwner;
        owner = newOwner;
        emit NewOwner(oldOWner, newOwner);
    }
}