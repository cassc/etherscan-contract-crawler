// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IAMB {
    function messageSender() external view returns (address);
    function maxGasPerTx() external view returns (uint256);
    function transactionHash() external view returns (bytes32);
    function messageId() external view returns (bytes32);
    function messageSourceChainId() external view returns (bytes32);
    function messageCallStatus(bytes32 _messageId) external view returns (bool);
    function failedMessageDataHash(bytes32 _messageId) external view returns (bytes32);
    function failedMessageReceiver(bytes32 _messageId) external view returns (address);
    function failedMessageSender(bytes32 _messageId) external view returns (address);
    function requireToPassMessage(address _contract, bytes calldata _data, uint256 _gas) external returns (bytes32);
    function requireToConfirmMessage(address _contract,  bytes calldata _data, uint256 _gas) external returns (bytes32);
    function requireToGetInformation(bytes32 _requestSelector,  bytes calldata _data) external returns (bytes32);
    function sourceChainId() external view returns (uint256);
    function destinationChainId() external view returns (uint256);
}
