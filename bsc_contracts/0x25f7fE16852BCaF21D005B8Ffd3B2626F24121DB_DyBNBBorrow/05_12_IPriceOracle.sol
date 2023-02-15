// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IPriceOracle {
    function getUnderlyingPrice(address vToken) external view returns (uint256);
}