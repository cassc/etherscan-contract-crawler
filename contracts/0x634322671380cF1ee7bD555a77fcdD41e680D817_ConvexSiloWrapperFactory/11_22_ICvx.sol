// SPDX-License-Identifier: MIT
// Original Copyright 2021 convex-eth
// Original source: https://github.com/convex-eth/platform/blob/669033cd06704fc67d63953078f42150420b6519/contracts/contracts/interfaces/ICvx.sol
pragma solidity 0.6.12;

interface ICvx {
    function reductionPerCliff() external view returns(uint256);
    function totalSupply() external view returns(uint256);
    function totalCliffs() external view returns(uint256);
    function maxSupply() external view returns(uint256);
}