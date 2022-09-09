// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IOracle {
    function getUnderlyingPriceView(address cToken) external view returns (uint256);
}