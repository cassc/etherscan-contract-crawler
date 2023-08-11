// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStrongXNodeManager {
    function claim(address beneficiary, uint nodeAmount) external;
}