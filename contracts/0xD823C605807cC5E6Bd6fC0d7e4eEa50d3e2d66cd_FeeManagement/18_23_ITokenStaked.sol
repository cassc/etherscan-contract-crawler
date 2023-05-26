// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenStaked {
    function getTotalStaked() external view returns (uint256);
}