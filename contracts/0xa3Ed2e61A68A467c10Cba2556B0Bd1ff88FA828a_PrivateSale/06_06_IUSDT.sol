// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUSDT {
    function decimals() external returns (uint256);

    function allowance(address owner, address spender) external returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;

    function approve(address spender, uint256 value) external;

    function totalSupply() external returns (uint256);

    function balanceOf(address who) external returns (uint256);

    function transfer(address to, uint256 value) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}