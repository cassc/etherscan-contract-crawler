// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address guy, uint256 wad) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function withdraw(uint256) external;

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}