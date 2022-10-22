// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMinimaxToken {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function owner() external returns (address);
}