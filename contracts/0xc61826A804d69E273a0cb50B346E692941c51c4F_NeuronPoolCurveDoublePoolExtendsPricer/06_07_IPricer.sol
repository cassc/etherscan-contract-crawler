// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IPricer {
    function asset() external view returns (address);

    function getPrice() external view returns (uint256);

    function setExpiryPriceInOracle(uint256 _expiryTimestamp) external;
}