// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Treasury.sol";


contract FeesTreasury is Treasury, Ownable, ReentrancyGuard {

    function withdraw(
        string calldata reason,
        address token,
        uint256 amount,
        address to
    ) public onlyOwner nonReentrant {
        _withdraw(reason, token, amount, to);
    }

}