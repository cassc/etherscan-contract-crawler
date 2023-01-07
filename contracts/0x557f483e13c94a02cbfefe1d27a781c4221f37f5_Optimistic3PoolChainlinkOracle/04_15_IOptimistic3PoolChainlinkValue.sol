// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IOptimistic3PoolChainlinkValue {
    function value() external view returns (uint256 value_, bytes memory data);
}