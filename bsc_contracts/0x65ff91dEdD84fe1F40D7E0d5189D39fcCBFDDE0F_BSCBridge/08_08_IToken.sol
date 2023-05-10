// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IToken {

    function transferOwnership(address newOwner) external;

    function mint(address to, uint256 amount) external;

    function burn(address owner, uint256 amount) external;

    function transfer(address recipient, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);
}