//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIncreaseAmount {
    function increaseAmountBy(uint16 level_) external view returns (uint256);
}