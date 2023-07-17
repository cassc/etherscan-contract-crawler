// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

interface IPriceOracle {
    function getPrice() external view returns (uint256);
}