// Copyright 2022 Christian Felde
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Crystal.sol";

contract Donor {
    address public target;

    constructor(
        address _target
    ) {
        target = _target;
    }

    function mint(
        uint seed,
        string memory tag
    ) public returns (
        uint mintValue,
        bool progress
    ) {
        Crystal crystal = Crystal(target);

        if (seed % 2 == 0) {
            (mintValue, progress) = crystal.mint(seed, tag);
            crystal.transfer(msg.sender, crystal.balanceOf(address(this)));
        } else {
            (mintValue, progress) = crystal.mint(seed, "nupow.fi gift");
            crystal.transfer(block.coinbase, crystal.balanceOf(address(this)));
        }
    }
}