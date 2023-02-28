// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

interface IWormholeRouter {
    function transferTokens(
        address _token,
        uint256 _amountPlusFee,
        uint16 _recipientChain,
        bytes32 _targetAddress,
        uint256 _fee,
        uint32 _nonce
    ) external payable;

    function wrapAndTransferETH(
        uint16 _recipientChain,
        bytes32 _targetAddress,
        uint256 _fee,
        uint32 _nonce
    ) external payable;

    function transferTokensWithPayload(
        address _token,
        uint256 _finalInput,
        uint16 _recipientChain,
        bytes32 _targetAddress,
        uint32 _nonce,
        bytes calldata payload
    ) external payable;

    function wrapAndTransferETHWithPayload(
        uint16 _recipientChain,
        bytes32 _targetAddress,
        uint32 _nonce,
        bytes calldata payload
    ) external payable;
}