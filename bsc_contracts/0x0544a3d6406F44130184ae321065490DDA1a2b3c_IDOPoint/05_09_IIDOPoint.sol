// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IIDOPoint {
    function getPoint(address user) external view returns (uint256);
}