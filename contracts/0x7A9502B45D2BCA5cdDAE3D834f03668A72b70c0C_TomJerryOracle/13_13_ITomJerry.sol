// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITomJerry {
    function getMarketCap() external view returns (uint);
    function setIsDiscounted(bool active) external;
}