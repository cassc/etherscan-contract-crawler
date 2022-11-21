// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import 'sgn-v2-contracts/contracts/message/interfaces/IMessageReceiverApp.sol';
import './interfaces/IIFRetrievableStakeWeight.sol';
import './interfaces/IIFBridgableStakeWeight.sol';

contract IFAllocationMasterAdapter is
    IIFRetrievableStakeWeight,
    IIFBridgableStakeWeight
{
    // Celer Multichain Integration
    address public immutable messageBus;

    // Whitelisted Caller
    address public immutable srcAddress;
    uint24 public immutable srcChainId;

    // user checkpoint mapping -- (track, user address, timestamp) => UserStakeWeight
    mapping(uint24 => mapping(address => mapping(uint80 => uint192)))
        public userStakeWeights;

    // user checkpoint mapping -- (track, timestamp) => TotalStakeWeight
    mapping(uint24 => mapping(uint80 => uint192)) public totalStakeWeight;

    // MODIFIERS
    modifier onlyMessageBus() {
        require(msg.sender == messageBus, 'caller is not message bus');
        _;
    }

    // CONSTRUCTOR
    constructor(
        address _messageBus,
        address _srcAddress,
        uint24 _srcChainId
    ) {
        messageBus = _messageBus;
        srcAddress = _srcAddress;
        srcChainId = _srcChainId;
    }

    function getTotalStakeWeight(uint24 trackId, uint80 timestamp)
        external
        view
        returns (uint192)
    {
        return totalStakeWeight[trackId][timestamp];
    }

    function getUserStakeWeight(
        uint24 trackId,
        address user,
        uint80 timestamp
    ) public view returns (uint192) {
        return userStakeWeights[trackId][user][timestamp];
    }

    // Bridge functionalities

    /**
     * execute the bridged message sent by messageBus
     * @notice Called by MessageBus (MessageBusReceiver)
     * @param _sender The address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external onlyMessageBus returns (IMessageReceiverApp.ExecutionStatus) {
        // sender has to be source master address
        require(_sender == srcAddress, 'sender != srcAddress');

        // srcChainId has to be the same as source chain id
        require(_srcChainId == srcChainId, 'srcChainId != _srcChainId');

        // decode the message
        MessageRequest memory message = abi.decode(
            (_message),
            (MessageRequest)
        );

        if (message.bridgeType == BridgeType.UserWeight) {
            for (uint256 i = 0; i < message.users.length; i++) {
                userStakeWeights[message.trackId][message.users[i]][
                    message.timestamp
                ] = message.weights[i];
            }
        } else {
            totalStakeWeight[message.trackId][message.timestamp] = message
                .weights[0];
        }

        return IMessageReceiverApp.ExecutionStatus.Success;
    }
}