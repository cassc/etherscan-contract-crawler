//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/ILayerZeroReceiver.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract NonblockingReceiver is Ownable, ILayerZeroReceiver {
    ILayerZeroEndpoint internal _lzEndpoint;

    error LayerZero__InvalidSourceChainContract();
    error LayerZero__CallerNotLzEndpoint();
    error LayerZero__CallerNotBridge();
    error LayerZero__NoStoredMessage();
    error LayerZero__InvalidPayload();

    struct FailedMessages {
        uint256 payloadLength;
        bytes32 payloadHash;
    }

    mapping(uint16 => mapping(bytes => mapping(uint256 => FailedMessages)))
        public failedMessages;
    mapping(uint16 => bytes) public trustedRemoteLookup;

    event MessageFailed(
        uint16 _srcChainId,
        bytes _srcAddress,
        uint64 _nonce,
        bytes _payload
    );

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external override {
        if (msg.sender != address(_lzEndpoint))
            revert LayerZero__CallerNotLzEndpoint(); // boilerplate! lzReceive must be called by the endpoint for security
        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        if (
            _srcAddress.length != trustedRemote.length ||
            keccak256(_srcAddress) != keccak256(trustedRemote)
        ) revert LayerZero__InvalidSourceChainContract();

        // try-catch all errors/exceptions
        // having failed messages does not block messages passing
        // solhint-disable-next-line no-empty-blocks
        try this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
            // do nothing
        } catch {
            // error / exception
            failedMessages[_srcChainId][_srcAddress][_nonce] = FailedMessages(
                _payload.length,
                keccak256(_payload)
            );
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    function onLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) public {
        // only internal transaction
        if (msg.sender != address(this)) revert LayerZero__CallerNotBridge();

        // handle incoming message
        _lzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function
    function _lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _txParam
    ) internal {
        // solhint-disable-next-line check-send-result
        _lzEndpoint.send{value: msg.value}(
            _dstChainId,
            trustedRemoteLookup[_dstChainId],
            _payload,
            _refundAddress,
            _zroPaymentAddress,
            _txParam
        );
    }

    function retryMessage(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external payable {
        // assert there is message to retry
        FailedMessages storage failedMsg = failedMessages[_srcChainId][
            _srcAddress
        ][_nonce];
        if (failedMsg.payloadHash == bytes32(0))
            revert LayerZero__NoStoredMessage();
        if (
            _payload.length != failedMsg.payloadLength ||
            keccak256(_payload) != failedMsg.payloadHash
        ) revert LayerZero__InvalidPayload();
        // clear the stored message
        failedMsg.payloadLength = 0;
        failedMsg.payloadHash = bytes32(0);
        // execute the message. revert if it fails again
        this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function setTrustedRemote(uint16 _chainId, bytes calldata _trustedRemote)
        external
        onlyOwner
    {
        trustedRemoteLookup[_chainId] = _trustedRemote;
    }
}