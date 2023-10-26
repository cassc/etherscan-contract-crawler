// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBridgeHandle {

    function sendMessage(uint16 _dstChainId, bytes memory _payload, address payable _refundAddress, bytes memory _adapterParams, uint256 _nativeFee) payable external;

    function estimateFees(uint16 _dstChainId, bytes calldata _payload, bytes calldata _adapterParam) external view returns (uint256 fee);
}