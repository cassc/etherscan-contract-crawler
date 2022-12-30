// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

import "../external/Library.sol";
import "../external/IStargateRouter.sol";


/// @title Main contract which serves as the entry point
interface IMultichainPortal {
    struct StargateArgs {
        uint16 dstChainId;
        uint16 srcPoolId;
        uint16 dstPoolId;
        uint256 minAmountOut;
        IStargateRouter.lzTxObj lzTxObj;
        address receiver;
        bytes data;
    }

    struct Payload {
        address user;
        address swapRouter;
        bytes swapArguments;
        Types.ICall[] calls;
    }

    function swapERC20AndCall(
        address tokenIn,
        address[] memory tokenOuts,
        uint256 amountIn,
        address user,
        address swapRouter,
        bytes calldata swapArguments,
        Types.ICall[] calldata calls
    ) external;

    function swapNativeAndCall(
        address[] memory tokenOuts,
        address user,
        address swapRouter,
        bytes calldata swapArguments,
        Types.ICall[] calldata calls
    ) external payable;

    function swapERC20AndSend(
        uint amountIn,
        uint amountStargate,
        address user,
        address tokenIn,
        address tokenStargate,
        address swapRouter,
        bytes calldata swapArguments,
        StargateArgs memory stargateArgs
    ) external payable;

    function swapNativeAndSend(
        uint amountIn,
        uint amountStargate,
        uint lzFee,
        address user,
        address tokenStargate,
        address swapRouter,
        bytes calldata swapArguments,
        IMultichainPortal.StargateArgs memory stargateArgs
    ) external payable;
}