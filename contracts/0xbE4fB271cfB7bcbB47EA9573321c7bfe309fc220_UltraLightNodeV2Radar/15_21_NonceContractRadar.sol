// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./interfaces/ILayerZeroEndpoint.sol";

contract NonceContractRadar {
    ILayerZeroEndpoint public immutable endpoint;
    address public immutable ulnv2Radar;
    // outboundNonce = [dstChainId][remoteAddress + localAddress]
    mapping(uint16 => mapping(bytes => uint64)) public outboundNonce;

    constructor(address _endpoint, address _ulnv2Radar) {
        endpoint = ILayerZeroEndpoint(_endpoint);
        ulnv2Radar = _ulnv2Radar;
    }

    function increment(uint16 _chainId, address _ua, bytes calldata _path) external returns (uint64) {
        require(endpoint.getSendLibraryAddress(_ua) == msg.sender, "NonceContract: msg.sender is not valid sendlibrary");
        return ++outboundNonce[_chainId][_path];
    }

    // only ulnv2Radar can call this function
    function initRadarOutboundNonce(uint16 _dstChainId, bytes calldata _path, uint64 _nonce) external {
        require(msg.sender == ulnv2Radar, "NonceContract: only ulnv2Radar");
        outboundNonce[_dstChainId][_path] = _nonce;
    }
}