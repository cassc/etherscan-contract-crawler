// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

interface IWormholeRouter {
    function transferTokens(
        address _fromAddress,
        uint256 _finalInput,
        uint256 _recipientChain,
        bytes32 _targetAddress,
        uint256 _fee,
        uint256 _nonce
    ) external payable;

    function wrapAndTransferETH(
        uint256 _recipientChain,
        bytes32 _targetAddress,
        uint256 _fee,
        uint256 _nonce
    ) external payable;

    function transferTokensWithPayload(
        address _fromAddress,
        uint256 _finalInput,
        uint256 _recipientChain,
        bytes32 _targetAddress,
        uint256 _nonce,
        bytes calldata payload
    ) external payable;

    function wrapAndTransferETHWithPayload(
        uint256 _recipientChain,
        bytes32 _targetAddress,
        uint256 _nonce,
        bytes calldata payload
    ) external payable;
}