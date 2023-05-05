// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISaleContract {
    function getUserBuyAmount(address _address) external view returns (uint256);
}