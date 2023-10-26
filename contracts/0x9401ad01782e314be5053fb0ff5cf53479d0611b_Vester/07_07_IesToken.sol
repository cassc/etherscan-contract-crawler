// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IesToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function mint(address user, uint256 amount) external returns (bool);

    function burn(address user, uint256 amount) external returns (bool);
}