// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IAToken {
    function decimals() external returns (uint256);

    function transfer(address _recipient, uint256 _amount) external;

    function balanceOf(address _user) external view returns (uint256);
}