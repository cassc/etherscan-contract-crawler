// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISubscribers {
    function isSubscribed(address addr) external view returns (bool);
}