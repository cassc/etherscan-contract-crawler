// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

interface TokenFaucet {
    function claim(address user) external returns (uint256);

    function asset() external returns (address);

    function dripRatePerSecond() external returns (uint256);

    function exchangeRateMantissa() external returns (uint112);

    function measure() external returns (address);

    function totalUnclaimed() external returns (uint112);

    function lastDripTimestamp() external returns (uint32);
}