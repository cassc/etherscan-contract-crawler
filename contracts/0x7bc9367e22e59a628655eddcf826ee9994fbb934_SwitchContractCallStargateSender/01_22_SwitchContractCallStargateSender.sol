// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../dexs/Switch.sol";
import { IStargateRouter, IFactory, IPool } from "../interfaces/IStargateRouter.sol";
import { IStargateEthRouter } from "../interfaces/IStargateEthRouter.sol";
import "../lib/DataTypes.sol";

contract SwitchContractCallStargateSender is Switch {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    address public stargateRouter;

    struct ContractCallArgsStargate {
        DataTypes.SwapInfo srcSwap;
        DataTypes.SwapInfo dstSwap;
        address payable recipient;
        address partner;
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 amount;
        uint256 minDstAmount;
        uint256 bridgeDstAmount;
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        uint256 estimatedCallAmount;
        uint256[] srcDistribution;
        uint256[] dstDistribution;
        uint16  dstChainId;
        bytes32 id;
        bytes32 bridge;
        bytes callTo;
        bytes srcParaswapData;
        bytes dstParaswapData;
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
        DataTypes.ContractCallInfo callInfo;
    }

    event StargateRouterSet(address stargateRouter);
    event StargateEthRouterSet(address stargateEthRouter);

    constructor(
        address _weth,
        address _otherToken,
        uint256[] memory _pathCountAndSplit,
        address[] memory _factories,
        address _switchViewAddress,
        address _switchEventAddress,
        address _stargateRouter,
        address _paraswapProxy,
        address _augustusSwapper
    ) Switch(
        _weth,
        _otherToken,
        _pathCountAndSplit[0],
        _pathCountAndSplit[1],
        _factories,
        _switchViewAddress,
        _switchEventAddress,
        _paraswapProxy,
        _augustusSwapper
    )
        public
    {
        stargateRouter = _stargateRouter;
    }

    function setStargateRouter(address _newStargateRouter) external onlyOwner {
        stargateRouter = _newStargateRouter;
        emit StargateRouterSet(_newStargateRouter);
    }

    function getLayerZeroFee(
        DataTypes.ContractCallRequest calldata request,
        uint16 dstChainId,
        uint256 dstGasForCall,
        uint256 dstNativeAmount,
        address receiver
    )
        external
        view
        returns (uint256, uint256)
    {
        bytes memory message = abi.encode(
            DataTypes.ContractCallRequest({
                id: request.id,
                bridge: request.bridge,
                srcToken: request.srcToken,
                bridgeToken: request.bridgeToken,
                callToken: request.callToken,
                recipient: request.recipient,
                srcAmount: request.srcAmount,
                dstDistribution: request.dstDistribution,
                bridgeDstAmount: request.bridgeDstAmount,
                estimatedCallAmount: request.estimatedCallAmount,
                paraswapUsageStatus: request.paraswapUsageStatus,
                dstParaswapData: request.dstParaswapData,
                callInfo: request.callInfo
            })
        );

        return IStargateRouter(stargateRouter).quoteLayerZeroFee(
            dstChainId,
            1,                  // TYPE_SWAP_REMOTE on Bridge
            abi.encodePacked(receiver),
            message,
            IStargateRouter.lzTxObj(
                dstGasForCall,
                dstNativeAmount,
                abi.encodePacked(receiver)
            )
        );
    }

    function contractCallByStargate(
        ContractCallArgsStargate calldata callArgs
    )
        external
        payable
        nonReentrant
    {
        IERC20(callArgs.srcSwap.srcToken).universalTransferFrom(msg.sender, address(this), callArgs.amount);

        uint256 returnAmount = 0;
        uint256 amountAfterFee = _getAmountAfterFee(IERC20(callArgs.srcSwap.srcToken), callArgs.amount, callArgs.partner);

        if (callArgs.srcSwap.srcToken == callArgs.srcSwap.dstToken) {
            returnAmount = amountAfterFee;
        } else {
            if ((callArgs.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.OnSrcChain) ||
                (callArgs.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.Both))
            {
                returnAmount = _swapFromParaswap(callArgs, amountAfterFee);
            } else {
                (returnAmount, ) = _swapBeforeStargate(callArgs, amountAfterFee);
            }
        }

        bytes memory message = abi.encode(
            DataTypes.ContractCallRequest({
                id: callArgs.id,
                bridge: callArgs.bridge,
                srcToken: callArgs.srcSwap.srcToken,
                bridgeToken: callArgs.dstSwap.srcToken,
                callToken: callArgs.dstSwap.dstToken,
                recipient: callArgs.recipient,
                srcAmount: amountAfterFee,
                dstParaswapData: callArgs.dstParaswapData,
                paraswapUsageStatus: callArgs.paraswapUsageStatus,
                bridgeDstAmount: callArgs.bridgeDstAmount,
                estimatedCallAmount: callArgs.estimatedCallAmount,
                dstDistribution: callArgs.dstDistribution,
                callInfo: callArgs.callInfo
            })
        );

        (uint256 nativeFee, ) = _getLayerZeroFee(
            message,
            callArgs.dstChainId,
            callArgs.dstGasForCall,
            callArgs.dstNativeAmount,
            callArgs.callTo
        );

        if (IERC20(callArgs.srcSwap.srcToken).isETH()) {
            require(msg.value >= callArgs.amount + nativeFee, 'native token is not enough');
        } else {
            require(msg.value >= nativeFee, 'native token is not enough');
        }

        if (!IERC20(callArgs.srcSwap.dstToken).isETH()) {
            IERC20(callArgs.srcSwap.dstToken).universalApprove(stargateRouter, returnAmount);
        }

        IStargateRouter(stargateRouter).swap{ value: nativeFee }(
            callArgs.dstChainId,
            callArgs.srcPoolId,                         // source pool id
            callArgs.dstPoolId,                         // dest pool id
            callArgs.recipient,                         // refund adddress. extra gas (if any) is returned to this address
            returnAmount,                               // quantity to swap
            callArgs.minDstAmount,                      // the min qty you would accept on the destination
            IStargateRouter.lzTxObj(
                callArgs.dstGasForCall,
                callArgs.dstNativeAmount,
                callArgs.callTo
            ),
            callArgs.callTo,                            // the address to send the tokens to on the destination
            message                                     // bytes param, if you wish to send additional payload you can abi.encode() them here
        );

        _emitCrossChainContractCallRequest(
            callArgs,
            bytes32(0),
            returnAmount,
            msg.sender,
            DataTypes.ContractCallStatus.Succeeded
        );
    }

    function _swapFromParaswap(
        ContractCallArgsStargate calldata callArgs,
        uint256 amount
    )
        private
        returns (uint256 returnAmount)
    {
        // break function to avoid stack too deep error
        returnAmount = _swapInternalWithParaSwap(
            IERC20(callArgs.srcSwap.srcToken),
            IERC20(callArgs.srcSwap.dstToken),
            amount,
            callArgs.srcParaswapData
        );
    }

    function _swapBeforeStargate(
        ContractCallArgsStargate calldata callArgs,
        uint256 amount
    )
        private
        returns (
            uint256 returnAmount,
            uint256 parts
        )
    {
        parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint i = 0; i < callArgs.srcDistribution.length; i++) {
            if (callArgs.srcDistribution[i] > 0) {
                parts += callArgs.srcDistribution[i];
                lastNonZeroIndex = i;
            }
        }

        require(parts > 0, "invalid distribution param");
        // break function to avoid stack too deep error
        returnAmount = _swapInternalForSingleSwap(
            callArgs.srcDistribution,
            amount,
            parts,
            lastNonZeroIndex,
            IERC20(callArgs.srcSwap.srcToken),
            IERC20(callArgs.srcSwap.dstToken)
        );
        require(returnAmount > 0, "Swap failed from dex");

        switchEvent.emitSwapped(
            msg.sender,
            address(this),
            IERC20(callArgs.srcSwap.srcToken),
            IERC20(callArgs.srcSwap.dstToken),
            amount,
            returnAmount,
            0
        );
    }

    function _getLayerZeroFee(
        bytes memory message,
        uint16 dstChainId,
        uint256 dstGasForCall,
        uint256 dstNativeAmount,
        bytes memory receiver
    )
        internal
        view
        returns(uint256, uint256)
    {

        return IStargateRouter(stargateRouter).quoteLayerZeroFee(
            dstChainId,
            1,                  // TYPE_SWAP_REMOTE on Bridge
            receiver,
            message,
            IStargateRouter.lzTxObj(
                dstGasForCall,
                dstNativeAmount,
                receiver
            )
        );
    }

    function _emitCrossChainContractCallRequest(
        ContractCallArgsStargate calldata callArgs,
        bytes32 transferId,
        uint256 returnAmount,
        address sender,
        DataTypes.ContractCallStatus status
    )
        internal
    {
        switchEvent.emitCrosschainContractCallRequest(
            callArgs.id,
            transferId,
            callArgs.bridge,
            sender,
            callArgs.callInfo.toContractAddress,
            callArgs.callInfo.toApprovalAddress,
            callArgs.srcSwap.srcToken,
            callArgs.dstSwap.dstToken,
            returnAmount,
            callArgs.estimatedCallAmount,
            status
        );
    }
}