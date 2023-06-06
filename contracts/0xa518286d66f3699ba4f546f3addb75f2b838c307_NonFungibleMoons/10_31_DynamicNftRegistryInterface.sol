// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {OwnerPermissionedTokenRegistryInterface} from "./OwnerPermissionedTokenRegistryInterface.sol";

/**
 * @title  DynamicNftRegistry
 * @author James Wenzel (emo.eth)
 * @notice Interface for an open registry for allowed updaters of token contracts to register that a (potentially
 *         off-chain) metadata update has occurred on-chain, inheriting from OwnerPermissionedTokenRegistryInterface.
 */
interface DynamicNftRegistryInterface is
    OwnerPermissionedTokenRegistryInterface
{
    /**
     * @notice update token's last modified timestamp to timestamp of current block
     * @param tokenAddress address of the token contract
     * @param tokenId that has been updated
     * @param cooldownPeriod in seconds
     */
    function updateToken(
        address tokenAddress,
        uint256 tokenId,
        uint64 cooldownPeriod,
        bool invalidateCollectionOrders
    ) external;

    /**
     * @notice update token's last modified timestamp to a timestamp in the past
     * @param tokenAddress address of the token contract
     * @param tokenId that has been updated
     * @param timestamp specific timestamp when token was last updated
     * @param cooldownPeriod in seconds
     */
    function updateToken(
        address tokenAddress,
        uint256 tokenId,
        uint64 timestamp,
        uint64 cooldownPeriod,
        bool invalidateCollectionOrders
    ) external;
}