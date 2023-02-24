// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../utils/Ownable.sol";

contract MockOwnable is Ownable {
    constructor(address owner_) Ownable(owner_) {}

    function ownerFunction() external onlyOwner {}

    function publicFunction() external {}
}