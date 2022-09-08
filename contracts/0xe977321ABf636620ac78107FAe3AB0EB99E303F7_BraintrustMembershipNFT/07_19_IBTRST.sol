// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IBTRST {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 rawAmount)
        external
        returns (bool);

    function transfer(address dst, uint256 rawAmount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 rawAmount
    ) external returns (bool);
}