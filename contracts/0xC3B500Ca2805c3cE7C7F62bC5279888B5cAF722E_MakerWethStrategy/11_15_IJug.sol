// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface IJug {
    function drip(bytes32) external returns (uint256);
}