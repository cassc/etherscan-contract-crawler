// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct VRFManagerConstructorArgs {
    uint64 subscriptionId;
    address vrfCoordinator;
    bytes32 keyHash;
    uint32 callbackGasLimitMultiplier;
    uint32 callbackGasLimitBase;
    uint16 requestConfirmations;
}

contract VRFManager is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface public COORDINATOR;
    uint64 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimitMultiplier;
    uint32 public callbackGasLimitBase;
    uint16 public requestConfirmations;

    constructor(VRFManagerConstructorArgs memory _VRFManagerConstructorArgs)
        VRFConsumerBaseV2(_VRFManagerConstructorArgs.vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            _VRFManagerConstructorArgs.vrfCoordinator
        );
        subscriptionId = _VRFManagerConstructorArgs.subscriptionId;
        keyHash = _VRFManagerConstructorArgs.keyHash;
        callbackGasLimitMultiplier = _VRFManagerConstructorArgs
            .callbackGasLimitMultiplier;
        callbackGasLimitBase = _VRFManagerConstructorArgs.callbackGasLimitBase;
        requestConfirmations = _VRFManagerConstructorArgs.requestConfirmations;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual
        override
    {}

    function updateSubscriptionId(uint64 _subscriptionId) public virtual {
        subscriptionId = _subscriptionId;
    }

    function updateKeyHash(bytes32 _keyHash) public virtual {
        keyHash = _keyHash;
    }

    function updateCallbackGasLimits(
        uint32 _callbackGasLimitMultiplier,
        uint32 _callbackGasLimitBase
    ) public virtual {
        callbackGasLimitMultiplier = _callbackGasLimitMultiplier;
        callbackGasLimitBase = _callbackGasLimitBase;
    }

    function updateRequestConfirmations(uint16 _requestConfirmations)
        public
        virtual
    {
        require(
            _requestConfirmations >= 3,
            "updateRequestConfirmations: request confirmations must be at least 3"
        );
        requestConfirmations = _requestConfirmations;
    }
}