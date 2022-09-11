// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import "./IStargatePool.sol";

interface IStargateFactory {
    function allPoolsLength() external view returns (uint256);

    function allPools(uint256 index) external view returns (IStargatePool);

    function getPool(uint256 _poolId) external view returns (IStargatePool);
}