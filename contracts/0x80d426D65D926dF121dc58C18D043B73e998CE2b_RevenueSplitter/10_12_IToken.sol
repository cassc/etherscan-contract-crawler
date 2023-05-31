// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface TokenLike {
    function approve(address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256) external;

    function decimals() external view returns (uint256);
}