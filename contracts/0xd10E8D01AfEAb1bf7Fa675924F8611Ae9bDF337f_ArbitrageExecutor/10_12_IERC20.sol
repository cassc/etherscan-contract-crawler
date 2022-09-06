//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IErc20 {
    function approve(address recipient, uint256 amount) external returns (bool);

    function transfer(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}