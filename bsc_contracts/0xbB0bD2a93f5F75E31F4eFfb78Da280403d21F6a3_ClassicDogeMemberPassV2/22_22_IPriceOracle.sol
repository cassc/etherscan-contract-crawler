//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPriceOracle {
    function getUnderlyingPrice(address _token) external view returns (uint256);
}