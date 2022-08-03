// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import {RNGInterface} from "./RNGInterface.sol";

/**
 * @title RNG Chainlink V2 Interface
 * @notice Provides an interface for requesting random numbers from Chainlink VRF V2.
 */
interface RNGChainlinkV2Interface is RNGInterface {
    /**
     * @notice Get Chainlink VRF keyHash associated with this contract.
     * @return bytes32 Chainlink VRF keyHash
     */
    function getKeyHash() external view returns (bytes32);

    /**
     * @notice Get Chainlink VRF subscription id associated with this contract.
     * @return uint64 Chainlink VRF subscription id
     */
    function getSubscriptionId() external view returns (uint64);

    /**
     * @notice Get Chainlink VRF coordinator contract address associated with this contract.
     * @return address Chainlink VRF coordinator address
     */
    function getVrfCoordinator()
        external
        view
        returns (VRFCoordinatorV2Interface);

    /**
     * @notice Set Chainlink VRF keyHash.
     * @dev This function is only callable by the owner.
     * @param keyHash Chainlink VRF keyHash
     */
    function setKeyhash(bytes32 keyHash) external;

    /**
     * @notice Set Chainlink VRF subscription id associated with this contract.
     * @dev This function is only callable by the owner.
     * @param subscriptionId Chainlink VRF subscription id
     */
    function setSubscriptionId(uint64 subscriptionId) external;
}