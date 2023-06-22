// Copyright 2022 Christian Felde
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Crystal is IERC20 {
    function mint(
        uint seed,
        string memory tag
    ) external returns (
        uint mintValue,
        bool progress
    );
}