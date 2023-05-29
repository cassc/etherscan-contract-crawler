// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface IYieldToken {
    function redeem(address, uint256) external returns (uint256);

    function underlying() external returns (address);

    function maturity() external view returns (uint256);
}