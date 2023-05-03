// SPDX-License-Identifier: GPL-3.0-or-later.
// Copyright (C) 2023 Spiral DAO, [email protected]
// Full Notice is available in the root folder.
pragma solidity ^0.8.0;

interface IStaking {
    function stake(uint256) external;
    function unstake(uint256) external;
    function index() external view returns(uint256);
}