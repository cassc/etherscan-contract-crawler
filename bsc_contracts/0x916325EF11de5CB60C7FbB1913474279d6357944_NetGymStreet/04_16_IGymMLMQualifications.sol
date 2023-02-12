// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface IGymMLMQualifications {
    function getUserCurrentLevel(address) external view returns (uint32);
}