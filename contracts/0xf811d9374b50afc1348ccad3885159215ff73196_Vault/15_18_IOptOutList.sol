// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOptOutList {
    function optedOut(address token) external view returns (bool status);
}