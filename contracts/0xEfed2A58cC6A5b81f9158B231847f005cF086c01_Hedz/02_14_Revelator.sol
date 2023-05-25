// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract Revelator is VRFConsumerBaseV2 {
    
    event RequestedRandomness(uint256 requestId, address invoker);
    
    VRFCoordinatorV2Interface private vrfCoordinator;
    bytes32 internal keyHash;
    uint64 internal subscriptionId;
    uint16 internal requestConfirmations = 3;
    uint32 internal callbackGasLimit;
    uint32 internal numWords =  1;    
    uint256 public metaOffset;
    bool public revealed;

    constructor(
        address _vrfCoordinator, 
        bytes32 _keyHash, 
        uint64 _subscriptionId
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        _setCoordinatorConfig(_vrfCoordinator, _keyHash, _subscriptionId, 200000);
    }

    function _reveal() internal {
        uint256 requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        emit RequestedRandomness(requestId, msg.sender);
    }

    function _setCoordinatorConfig(
        address _vrfCoordinator, 
        bytes32 _keyHash,
        uint64 _subscriptionId,        
        uint32 _gasCallbackLimit
    ) internal {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);        
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;            
        callbackGasLimit = _gasCallbackLimit;
    }

    function fulfillRandomWords(
        uint256 requestId, 
        uint256[] memory randomWords
    ) internal override {        
        metaOffset = randomWords[0] % 1000;
        revealed = true;
    }
}