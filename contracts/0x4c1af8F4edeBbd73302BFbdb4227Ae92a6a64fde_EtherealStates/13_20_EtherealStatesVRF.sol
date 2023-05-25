// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {VRFCoordinatorV2Interface} from '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import {VRFConsumerBaseV2} from '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';

/// @title EtherealStatesVRF
/// @author Artist: GenuineHumanArt (https://twitter.com/GenuineHumanArt)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
/// @notice EtherealStates VRF logic
contract EtherealStatesVRF is VRFConsumerBaseV2 {
    struct VRFConfig {
        bytes32 keyHash;
        address coordinator;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
        uint32 numWords;
    }

    /// @notice ChainLink request id
    uint256 public requestId;

    /// @notice ChainLink config
    VRFConfig public vrfConfig;

    constructor(VRFConfig memory vrfConfig_)
        VRFConsumerBaseV2(vrfConfig_.coordinator)
    {
        vrfConfig = vrfConfig_;
    }

    /// @dev basic call using the vrfConfig
    function _requestRandomWords() internal virtual {
        VRFConfig memory vrfConfig_ = vrfConfig;
        // Will revert if subscription is not set and funded.
        requestId = VRFCoordinatorV2Interface(vrfConfig_.coordinator)
            .requestRandomWords(
                vrfConfig_.keyHash,
                vrfConfig_.subscriptionId,
                vrfConfig_.requestConfirmations,
                vrfConfig_.callbackGasLimit,
                vrfConfig_.numWords
            );
    }

    /// @dev needs to be overrode in the consumer contract
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory
    ) internal virtual override {}
}