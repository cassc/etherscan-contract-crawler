// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IBurnableAdmin {
    function setBurnablePausedUntil(uint256 newTimestamp) external;
}