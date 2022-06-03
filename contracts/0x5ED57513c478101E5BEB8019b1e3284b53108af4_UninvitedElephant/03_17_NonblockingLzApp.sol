// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroEndpoint.sol";
import "../interfaces/ILayerZeroUserApplicationConfig.sol";

abstract contract NonblockingLzApp is Ownable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    ILayerZeroEndpoint public endpoint;

    struct FailedMessages {
        uint payloadLength;
        bytes32 payloadHash;
    }

    mapping(uint16 => mapping(bytes => mapping(uint => FailedMessages))) public failedMessages;
    mapping(uint16 => bytes) public trustedRemoteLookup;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload);

    event SendToChain(address indexed _sender, uint16 indexed _dstChainId, bytes _payload, uint64 _nonce);

    constructor(address _layerZeroEndpoint){
        endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
    }

    // abstract function
    function _LzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) virtual internal;

    function lzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) external override {
        require(_msgSender() == address(endpoint)); // boilerplate! lzReceive must be called by the endpoint for security
        require(_srcAddress.length == trustedRemoteLookup[_srcChainId].length && keccak256(_srcAddress) == keccak256(trustedRemoteLookup[_srcChainId]), "NonblockingLzApp: Invalid source sending contract");

        // try-catch all errors/exceptions
        // having failed messages does not block messages passing
        try this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
            // do nothing
        } catch {
            // error / exception
            failedMessages[_srcChainId][_srcAddress][_nonce] = FailedMessages(_payload.length, keccak256(_payload));
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    function onLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) public {
        // only internal transaction
        require(msg.sender == address(this), "NonblockingLzApp: Caller must be Bridge.");
        _LzReceive( _srcChainId, _srcAddress, _nonce, _payload);
    }

    function _lzSend(uint16 _dstChainId, bytes memory _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _txParam) internal {
        endpoint.send{value: msg.value}(_dstChainId, trustedRemoteLookup[_dstChainId], _payload, _refundAddress, _zroPaymentAddress, _txParam);

        uint64 nonce = endpoint.getOutboundNonce(_dstChainId, address(this));
        emit SendToChain(_msgSender(), _dstChainId, _payload, nonce);
    }

    function retryMessage(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes calldata _payload) external payable {
        // assert there is message to retry
        FailedMessages storage failedMsg = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(failedMsg.payloadHash != bytes32(0), "NonblockingLzApp: No stored message");
        require(_payload.length == failedMsg.payloadLength && keccak256(_payload) == failedMsg.payloadHash, "NonblockingLzApp: Invalid payload");
        // clear the stored message
        failedMsg.payloadLength = 0;
        failedMsg.payloadHash = bytes32(0);
        // execute the message. revert if it fails again
        this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function setTrustedRemote(uint16 _chainId, bytes calldata _trustedSource) external onlyOwner {
        require(trustedRemoteLookup[_chainId].length == 0, "NonblockingLzApp: The trusted source address has already been set for the chainId!");
        trustedRemoteLookup[_chainId] = _trustedSource;
    }

      // User Application Config
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external override onlyOwner {
        endpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        endpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        endpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        endpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }
}