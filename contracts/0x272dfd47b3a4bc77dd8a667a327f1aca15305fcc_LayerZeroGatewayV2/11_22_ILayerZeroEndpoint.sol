// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title ILayerZeroEndpoint
 * @notice LayerZero endpoint interface
 */
interface ILayerZeroEndpoint {
    /**
     * @notice Send a cross-chain message
     * @param _dstChainId The destination chain identifier
     * @param _destination Remote address concatenated with local address packed into 40 bytes
     * @param _payload The message content
     * @param _refundAddress Refund the additional amount to this address
     * @param _zroPaymentAddress The address of the ZRO token holder who would pay for the transaction
     * @param _adapterParam Parameters for the adapter service
     */
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParam
    ) external payable;

    /**
     * @notice Cross-chain message fee estimation
     * @param _dstChainId The destination chain identifier
     * @param _userApplication The application address on the source chain
     * @param _payload The message content
     * @param _payInZRO If false, the user application pays the protocol fee in the native token
     * @param _adapterParam Parameters for the adapter service
     * @return nativeFee The native token fee for the message
     * @return zroFee The ZRO token fee for the message
     */
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);
}