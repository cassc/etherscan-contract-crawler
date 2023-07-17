// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IEqbMsgSendEndpoint {
    function calcFee(
        uint256 _dstChainId,
        address _dstAddress,
        bytes memory _payload,
        uint256 _estimatedGasAmount
    ) external view returns (uint256 fee);

    function sendMessage(
        uint256 _dstChainId,
        address _dstAddress,
        bytes calldata _payload,
        uint256 _estimatedGasAmount
    ) external payable;

    event MsgSent(
        uint256 _dstChainId,
        address _dstAddress,
        bytes _payload,
        uint256 _estimatedGasAmount
    );
}