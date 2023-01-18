// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// taking from the verified code here - https://polygonscan.com/address/0x88DCDC47D2f83a99CF0000FDF667A468bB958a78#code
interface ICBridge {
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage // not easy to calculate, check https://cbridge-docs.celer.network/developer/api-reference/gateway-estimateamt
    ) external;

    // I did not have a chance to check it on mainnet, because cBrdige does not support BNB neither MATIC
    function sendNative(
        address _receiver,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external payable;

    event Send(
        bytes32 transferId,
        address sender,
        address receiver,
        address token,
        uint256 amount,
        uint64 dstChainId,
        uint64 nonce,
        uint32 maxSlippage
    );

    event Relay(
        bytes32 transferId,
        address sender,
        address receiver,
        address token,
        uint256 amount,
        uint64 srcChainId,
        bytes32 srcTransferId
    );
}