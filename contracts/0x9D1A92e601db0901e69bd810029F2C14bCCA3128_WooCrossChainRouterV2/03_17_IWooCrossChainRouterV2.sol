// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

/*

░██╗░░░░░░░██╗░█████╗░░█████╗░░░░░░░███████╗██╗
░██║░░██╗░░██║██╔══██╗██╔══██╗░░░░░░██╔════╝██║
░╚██╗████╗██╔╝██║░░██║██║░░██║█████╗█████╗░░██║
░░████╔═████║░██║░░██║██║░░██║╚════╝██╔══╝░░██║
░░╚██╔╝░╚██╔╝░╚█████╔╝╚█████╔╝░░░░░░██║░░░░░██║
░░░╚═╝░░░╚═╝░░░╚════╝░░╚════╝░░░░░░░╚═╝░░░░░╚═╝

*
* MIT License
* ===========
*
* Copyright (c) 2020 WooTrade
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/// @title WOOFi cross chain router interface (version 2).
/// @notice functions to interface with WOOFi cross chain swap.
interface IWooCrossChainRouterV2 {
    /* ----- Structs ----- */

    struct SrcInfos {
        address fromToken;
        address bridgeToken;
        uint256 fromAmount;
        uint256 minBridgeAmount;
    }

    struct DstInfos {
        uint16 chainId;
        address toToken;
        address bridgeToken;
        uint256 minToAmount;
        uint256 airdropNativeAmount;
    }

    /* ----- Events ----- */

    event WooCrossSwapOnSrcChain(
        uint256 indexed refId,
        address indexed sender,
        address indexed to,
        address fromToken,
        uint256 fromAmount,
        uint256 minBridgeAmount,
        uint256 realBridgeAmount
    );

    event WooCrossSwapOnDstChain(
        uint256 indexed refId,
        address indexed sender,
        address indexed to,
        address bridgedToken,
        uint256 bridgedAmount,
        address toToken,
        address realToToken,
        uint256 minToAmount,
        uint256 realToAmount
    );

    /* ----- State Variables ----- */

    function weth() external view returns (address);

    function bridgeSlippage() external view returns (uint256);

    function dstGasForSwapCall() external view returns (uint256);

    function dstGasForNoSwapCall() external view returns (uint256);

    function sgChainIdLocal() external view returns (uint16);

    function wooCrossChainRouters(uint16 chainId) external view returns (address wooCrossChainRouter);

    function sgETHs(uint16 chainId) external view returns (address sgETH);

    function sgPoolIds(uint16 chainId, address token) external view returns (uint256 poolId);

    /* ----- Functions ----- */

    function crossSwap(
        uint256 refId,
        address payable to,
        SrcInfos memory srcInfos,
        DstInfos memory dstInfos
    ) external payable;

    function sgReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint256 nonce,
        address bridgedToken,
        uint256 amountLD,
        bytes memory payload
    ) external;

    function quoteLayerZeroFee(
        uint256 refId,
        address to,
        SrcInfos memory srcInfos,
        DstInfos memory dstInfos
    ) external view returns (uint256 nativeAmount, uint256 zroAmount);

    function allDirectBridgeTokens() external view returns (address[] memory tokens);

    function allDirectBridgeTokensLength() external view returns (uint256 length);
}