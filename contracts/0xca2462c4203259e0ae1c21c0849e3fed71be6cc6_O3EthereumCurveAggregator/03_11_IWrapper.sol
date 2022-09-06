// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IWrapper {
    function bridgeOut(
        address pTokenAddress,
        uint256 amount,
        uint64 toChainId,
        bytes memory toAddress,
        bytes memory callData
    ) external payable returns(bool);

    function swapAndBridgeOut(
        address poolAddress, address tokenFrom, address tokenTo, uint256 dx, uint256 minDy, uint256 deadline, // args for swap
        uint64 toChainId, bytes memory toAddress, bytes memory callData                                       // args for bridge
    ) external payable returns(bool);

    function swapAndBridgeOutNativeToken(
        address poolAddress, address tokenTo, uint256 dx, uint256 minDy, uint256 deadline, // args for swap
        uint64 toChainId, bytes memory toAddress, bytes memory callData                    // args for bridge
    ) external payable returns(bool);

    function depositAndBridgeOut(
        address originalToken,
        address pTokenAddress,
        uint256 amount,
        uint64 toChainId,
        bytes memory toAddress,
        bytes memory callData
    ) external payable returns(bool);

    function depositAndBridgeOutNativeToken(
        address pTokenAddress,
        uint256 amount,
        uint64 toChainId,
        bytes memory toAddress,
        bytes memory callData
    ) external payable returns(bool);

    function bridgeOutAndWithdraw(
        address pTokenAddress,
        uint64 toChainId,
        bytes memory toAddress,
        uint256 amount
    ) external payable returns(bool);
}