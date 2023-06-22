// contracts/King.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./King.sol";

contract TestKing is King {
    uint256 public constant RESERVE = 1000000000 ether;

    constructor() King() {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}