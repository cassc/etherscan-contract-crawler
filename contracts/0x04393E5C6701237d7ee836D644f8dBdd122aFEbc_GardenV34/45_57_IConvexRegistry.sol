// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IBooster} from './external/convex/IBooster.sol';

/**
 * @title IConvexRegistry
 * @author Babylon Finance
 *
 * Interface for interacting with all the convex pools
 */
interface IConvexRegistry {
    /* ============ Functions ============ */

    function updateCache() external;

    /* ============ View Functions ============ */

    function getPid(address _asset) external view returns (bool, uint256);

    function convexPools(address _convexAddress) external view returns (bool);

    function booster() external view returns (IBooster);

    function getRewardPool(address _asset) external view returns (address reward);

    function getConvexInputToken(address _pool) external view returns (address inputToken);

    function getAllConvexPools() external view returns (address[] memory);
}