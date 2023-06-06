// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IGasOracle} from "./interfaces/IGasOracle.sol";
import {Messenger} from "./Messenger.sol";
import {MessengerProtocol} from "./interfaces/IBridge.sol";
import {WormholeMessenger} from "./WormholeMessenger.sol";

/**
 * @dev This abstract contract provides functions for cross-chain communication and supports different messaging
 *      protocols.
 */
abstract contract MessengerGateway is Ownable {
    Messenger private allbridgeMessenger;
    WormholeMessenger private wormholeMessenger;

    constructor(Messenger allbridgeMessenger_, WormholeMessenger wormholeMessenger_) {
        allbridgeMessenger = allbridgeMessenger_;
        wormholeMessenger = wormholeMessenger_;
    }

    /**
     * @dev Sets the Allbridge Messenger contract address.
     * @param allbridgeMessenger_ The address of the Messenger contract.
     */
    function setAllbridgeMessenger(Messenger allbridgeMessenger_) external onlyOwner {
        allbridgeMessenger = allbridgeMessenger_;
    }

    /**
     * @dev Sets the Wormhole Messenger contract address.
     * @param wormholeMessenger_ The address of the WormholeMessenger contract.
     */
    function setWormholeMessenger(WormholeMessenger wormholeMessenger_) external onlyOwner {
        wormholeMessenger = wormholeMessenger_;
    }

    /**
     * @notice Get the gas cost of a messaging transaction on another chain in the current chain's native token.
     * @param chainId The ID of the chain where to send the message.
     * @param protocol The messenger used to send the message.
     * @return The calculated gas cost of the messaging transaction in the current chain's native token.
     */
    function getMessageCost(uint chainId, MessengerProtocol protocol) external view returns (uint) {
        if (protocol == MessengerProtocol.Allbridge) {
            return allbridgeMessenger.getTransactionCost(chainId);
        } else if (protocol == MessengerProtocol.Wormhole) {
            return wormholeMessenger.getTransactionCost(chainId);
        }
        return 0;
    }

    /**
     * @notice Get the amount of gas a messaging transaction uses on a given chain.
     * @param chainId The ID of the chain where to send the message.
     * @param protocol The messenger used to send the message.
     * @return The amount of gas a messaging transaction uses.
     */
    function getMessageGasUsage(uint chainId, MessengerProtocol protocol) public view returns (uint) {
        if (protocol == MessengerProtocol.Allbridge) {
            return allbridgeMessenger.gasUsage(chainId);
        } else if (protocol == MessengerProtocol.Wormhole) {
            return wormholeMessenger.gasUsage(chainId);
        }
        return 0;
    }

    /**
     * @notice Checks whether a given message has been received via the specified messenger protocol.
     * @param message The message to check.
     * @param protocol The messenger used to send the message.
     * @return A boolean indicating whether the message has been received.
     */
    function hasReceivedMessage(bytes32 message, MessengerProtocol protocol) external view returns (bool) {
        if (protocol == MessengerProtocol.Allbridge) {
            return allbridgeMessenger.receivedMessages(message) != 0;
        } else if (protocol == MessengerProtocol.Wormhole) {
            return wormholeMessenger.receivedMessages(message) != 0;
        } else {
            revert("Not implemented");
        }
    }

    /**
     * @notice Checks whether a given message has been sent.
     * @param message The message to check.
     * @return A boolean indicating whether the message has been sent.
     */
    function hasSentMessage(bytes32 message) external view returns (bool) {
        return allbridgeMessenger.sentMessagesBlock(message) != 0 || wormholeMessenger.sentMessages(message) != 0;
    }

    function _sendMessage(bytes32 message, MessengerProtocol protocol) internal returns (uint messageCost) {
        if (protocol == MessengerProtocol.Allbridge) {
            messageCost = allbridgeMessenger.getTransactionCost(uint8(message[1]));
            allbridgeMessenger.sendMessage{value: messageCost}(message);
        } else if (protocol == MessengerProtocol.Wormhole) {
            messageCost = wormholeMessenger.getTransactionCost(uint8(message[1]));
            wormholeMessenger.sendMessage{value: messageCost}(message);
        } else {
            revert("Not implemented");
        }
    }
}