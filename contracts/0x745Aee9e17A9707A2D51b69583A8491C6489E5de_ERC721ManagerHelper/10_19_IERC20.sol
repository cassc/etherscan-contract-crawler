// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IERC20 {
    function burn(address recipient, uint256 amount) external;
}