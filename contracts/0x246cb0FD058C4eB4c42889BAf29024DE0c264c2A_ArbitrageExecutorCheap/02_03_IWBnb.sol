//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

interface IWBnb {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}