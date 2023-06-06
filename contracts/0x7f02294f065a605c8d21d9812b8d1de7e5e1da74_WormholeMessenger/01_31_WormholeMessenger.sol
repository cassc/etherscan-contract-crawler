// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IGasOracle} from "./interfaces/IGasOracle.sol";
import {IMessenger} from "./interfaces/IMessenger.sol";
import {IWormhole} from "./interfaces/IWormhole.sol";
import {GasUsage} from "./GasUsage.sol";
import {GasOracle} from "./GasOracle.sol";
import {HashUtils} from "./libraries/HashUtils.sol";

contract WormholeMessenger is Ownable, GasUsage {
    using HashUtils for bytes32;

    IWormhole private immutable wormhole;
    uint public immutable chainId;
    bytes32 public otherChainIds;

    uint32 private nonce;
    uint8 private commitmentLevel;

    mapping(uint16 chainId => bytes32 wormholeMessengerAddress) private otherWormholeMessengers;

    mapping(bytes32 messageHash => uint isReceived) public receivedMessages;
    mapping(bytes32 messageHash => uint isSent) public sentMessages;

    event MessageSent(bytes32 indexed message, uint64 sequence);
    event MessageReceived(bytes32 indexed message, uint64 sequence);
    event Received(address, uint);

    constructor(
        uint chainId_,
        bytes32 otherChainIds_,
        IWormhole wormhole_,
        uint8 commitmentLevel_,
        IGasOracle gasOracle_
    ) GasUsage(gasOracle_) {
        chainId = chainId_;
        otherChainIds = otherChainIds_;
        wormhole = wormhole_;
        commitmentLevel = commitmentLevel_;
    }

    function sendMessage(bytes32 message) external payable {
        require(uint8(message[0]) == chainId, "WormholeMessenger: wrong chainId");
        require(otherChainIds[uint8(message[1])] != 0, "Messenger: wrong destination");
        bytes32 messageWithSender = message.hashWithSenderAddress(msg.sender);

        uint32 nonce_ = nonce;

        uint64 sequence = wormhole.publishMessage(nonce_, abi.encodePacked(messageWithSender), commitmentLevel);

        unchecked {
            nonce = nonce_ + 1;
        }

        require(sentMessages[messageWithSender] == 0, "WormholeMessenger: has message");
        sentMessages[messageWithSender] = 1;

        emit MessageSent(messageWithSender, sequence);
    }

    function receiveMessage(bytes memory encodedMsg) external {
        (IWormhole.VM memory vm, bool valid, string memory reason) = wormhole.parseAndVerifyVM(encodedMsg);

        require(valid, reason);
        require(vm.payload.length == 32, "WormholeMessenger: wrong length");

        bytes32 messageWithSender = bytes32(vm.payload);
        require(uint8(messageWithSender[1]) == chainId, "WormholeMessenger: wrong chainId");

        require(otherWormholeMessengers[vm.emitterChainId] == vm.emitterAddress, "WormholeMessenger: wrong emitter");

        receivedMessages[messageWithSender] = 1;

        emit MessageReceived(messageWithSender, vm.sequence);
    }

    function setCommitmentLevel(uint8 value) external onlyOwner {
        commitmentLevel = value;
    }

    function setOtherChainIds(bytes32 value) external onlyOwner {
        otherChainIds = value;
    }

    function registerWormholeMessenger(uint16 chainId_, bytes32 address_) external onlyOwner {
        otherWormholeMessengers[chainId_] = address_;
    }

    function withdrawGasTokens(uint amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    fallback() external payable {
        revert("Unsupported");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}