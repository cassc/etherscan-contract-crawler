// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IFeeDistributor{
    function burn(address coin, uint256 amount) external returns (bool);
}