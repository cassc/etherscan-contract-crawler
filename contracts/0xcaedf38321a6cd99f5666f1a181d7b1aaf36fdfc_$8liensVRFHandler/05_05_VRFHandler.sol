// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/// @title VRFHandler
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
contract VRFHandler {
    error OnlyCoordinatorCanFulfill(address have, address want);

    struct VRFConfig {
        bytes32 keyHash;
        address coordinator;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
        uint32 numWords;
    }

    /// @notice ChainLink request id to coordinator
    mapping(uint256 => address) public requestIdCoordinator;

    /////////////////////////////////////////////////////////
    // Gated Coordinator                                   //
    /////////////////////////////////////////////////////////

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls _fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        if (msg.sender != requestIdCoordinator[requestId]) {
            revert OnlyCoordinatorCanFulfill(
                msg.sender,
                requestIdCoordinator[requestId]
            );
        }

        _fulfillRandomWords(requestId, randomWords);
    }

    /////////////////////////////////////////////////////////
    // Internal                                            //
    /////////////////////////////////////////////////////////

    /// @dev basic call using the vrfConfig
    /// @param vrfConfig the VRF call configuration
    function _requestRandomWords(VRFConfig memory vrfConfig)
        internal
        virtual
        returns (uint256)
    {
        // Will revert if subscription is not set and funded.
        uint256 requestId = VRFCoordinatorV2Interface(vrfConfig.coordinator)
            .requestRandomWords(
                vrfConfig.keyHash,
                vrfConfig.subscriptionId,
                vrfConfig.requestConfirmations,
                vrfConfig.callbackGasLimit,
                vrfConfig.numWords
            );

        requestIdCoordinator[requestId] = vrfConfig.coordinator;

        return requestId;
    }

    /// @notice fulfillRandomness handles the VRF response.
    /// @dev this method will be called by rawFulfillRandomWords after checking caller
    /// @param - requestId The Id initially returned by requestRandomness
    /// @param - randomWords the VRF output expanded to the requested number of words
    function _fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory
    ) internal virtual {}
}