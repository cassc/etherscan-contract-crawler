// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/IPlug.sol";
import "../interfaces/ISocket.sol";
import "../utils/Ownable.sol";

contract Messenger is IPlug, Ownable(msg.sender) {
    // immutables
    address private immutable _socket;
    uint256 private immutable _chainSlug;

    bytes32 private _message;
    uint256 public msgGasLimit;

    bytes32 private constant _PING = keccak256("PING");
    bytes32 private constant _PONG = keccak256("PONG");

    uint256 public constant SOCKET_FEE = 0.001 ether;

    error NoSocketFee();

    constructor(address socket_, uint256 chainSlug_, uint256 msgGasLimit_) {
        _socket = socket_;
        _chainSlug = chainSlug_;

        msgGasLimit = msgGasLimit_;
    }

    receive() external payable {}

    function removeGas(address payable receiver_) external onlyOwner {
        receiver_.transfer(address(this).balance);
    }

    function sendLocalMessage(bytes32 message_) external {
        _updateMessage(message_);
    }

    function sendRemoteMessage(
        uint256 remoteChainSlug_,
        bytes32 message_
    ) external payable {
        bytes memory payload = abi.encode(_chainSlug, message_);
        _outbound(remoteChainSlug_, payload);
    }

    function inbound(
        uint256,
        bytes calldata payload_
    ) external payable override {
        require(msg.sender == _socket, "Counter: Invalid Socket");
        (uint256 localChainSlug, bytes32 msgDecoded) = abi.decode(
            payload_,
            (uint256, bytes32)
        );

        _updateMessage(msgDecoded);

        bytes memory newPayload = abi.encode(
            _chainSlug,
            msgDecoded == _PING ? _PONG : _PING
        );
        _outbound(localChainSlug, newPayload);
    }

    // settings
    function setSocketConfig(
        uint256 remoteChainSlug_,
        address remotePlug_,
        address switchboard_
    ) external onlyOwner {
        ISocket(_socket).connect(
            remoteChainSlug_,
            remotePlug_,
            switchboard_,
            switchboard_
        );
    }

    function message() external view returns (bytes32) {
        return _message;
    }

    function _updateMessage(bytes32 message_) private {
        _message = message_;
    }

    function _outbound(uint256 targetChain_, bytes memory payload_) private {
        if (!(address(this).balance >= SOCKET_FEE)) revert NoSocketFee();
        ISocket(_socket).outbound{value: SOCKET_FEE}(
            targetChain_,
            msgGasLimit,
            payload_
        );
    }
}