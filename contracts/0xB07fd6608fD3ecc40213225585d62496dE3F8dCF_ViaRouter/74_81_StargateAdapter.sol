// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./AdapterBase.sol";
import "../interfaces/external/IStargateRouter.sol";

contract StargateAdapter is AdapterBase {
    struct StargateArgs {
        uint16 _dstChainId;
        uint256 _srcPoolId;
        uint256 _dstPoolId;
        address payable _refundAddress;
        uint256 _minAmountLD;
        bytes _to;
    }

    /// @notice Adapter constructor
    /// @param target_ Target contract for this adapter
    constructor(address target_) AdapterBase(target_) {}

    /// @inheritdoc AdapterBase
    function call(
        address tokenIn,
        uint256 amountIn,
        uint256 extraNativeValue,
        bytes memory args
    ) external payable override {
        StargateArgs memory stargateArgs = abi.decode(args, (StargateArgs));

        Transfers.approve(tokenIn, target, amountIn);
        uint256 baseValue = (tokenIn == address(0)) ? amountIn : 0;
        IStargateRouter(target).swap{value: baseValue + extraNativeValue}(
            stargateArgs._dstChainId,
            stargateArgs._srcPoolId,
            stargateArgs._dstPoolId,
            stargateArgs._refundAddress,
            amountIn,
            stargateArgs._minAmountLD,
            IStargateRouter.lzTxObj(0, 0, "0x"),
            stargateArgs._to,
            "0x"
        );
    }
}