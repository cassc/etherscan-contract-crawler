// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ILayerZeroRouter {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint specified by our chainId.
    // @param _dstChainId - the destination chain identifier
    // @param _remoteAndLocalAddresses - remote address concated with local address packed into 40 bytes
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _remoteAndLocalAddresses,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;
}