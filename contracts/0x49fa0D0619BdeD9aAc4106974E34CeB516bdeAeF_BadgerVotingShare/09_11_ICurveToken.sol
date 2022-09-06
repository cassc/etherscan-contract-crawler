// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurveToken {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}