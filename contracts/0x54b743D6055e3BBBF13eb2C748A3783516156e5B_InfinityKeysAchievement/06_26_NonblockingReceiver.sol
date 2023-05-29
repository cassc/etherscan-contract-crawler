// SPDX-License-Identifier: MIT
// Infinity Keys 2022
pragma solidity ^0.8.4;

import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroEndpoint.sol";
import "./Authorized.sol";

abstract contract NonblockingReceiver is Authorized, ILayerZeroReceiver {
    ILayerZeroEndpoint internal endpoint;

    struct FailedMessages {
        uint256 payloadLength;
        bytes32 payloadHash;
    }

    mapping(uint16 => mapping(bytes => mapping(uint256 => FailedMessages))) public failedMessages;
    mapping(uint16 => bytes) public trustedRemoteLookup;

    event MessageFailed(
        uint16 _srcChainId,
        bytes _srcAddress,
        uint64 _nonce,
        bytes _payload
    );

    /**
    @dev Standard layerzero receive function
    */
    function lzReceive( uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload ) external override {
        require(msg.sender == address(endpoint)); 
        require(
            _srcAddress.length == trustedRemoteLookup[_srcChainId].length &&
                keccak256(_srcAddress) == keccak256(trustedRemoteLookup[_srcChainId]),
            "NonblockingReceiver: invalid source sending contract"
        );

        try this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
            // do nothing
        } catch {
            failedMessages[_srcChainId][_srcAddress][_nonce] = FailedMessages(
                _payload.length,
                keccak256(_payload)
            );
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    /**
    @dev Nonblocking receive handler
    */
    function onLzReceive( uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload ) public {
        require( msg.sender == address(this), "NonblockingReceiver: caller must be Bridge." );
        _LzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    /**
    @dev Abstract fucntion to be overwritten
    */
    function _LzReceive( uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload ) internal virtual;

    function _lzSend( uint16 _dstChainId, bytes memory _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _txParam ) internal {
        endpoint.send{value: msg.value}(
            _dstChainId,
            trustedRemoteLookup[_dstChainId],
            _payload,
            _refundAddress,
            _zroPaymentAddress,
            _txParam
        );
    }

    function retryMessage( uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes calldata _payload ) external payable {
        FailedMessages storage failedMsg = failedMessages[_srcChainId][_srcAddress][_nonce];
        require( failedMsg.payloadHash != bytes32(0), "NonblockingReceiver: no stored message" );
        require( _payload.length == failedMsg.payloadLength && keccak256(_payload) == failedMsg.payloadHash, "LayerZero: invalid payload" );
        failedMsg.payloadLength = 0;
        failedMsg.payloadHash = bytes32(0);
        this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    /**
    @dev Set correct contract address on other chains
    */    
    function setTrustedRemote(uint16 _chainId, bytes calldata _trustedRemote) external onlyOwner {
        trustedRemoteLookup[_chainId] = _trustedRemote;
    }
}