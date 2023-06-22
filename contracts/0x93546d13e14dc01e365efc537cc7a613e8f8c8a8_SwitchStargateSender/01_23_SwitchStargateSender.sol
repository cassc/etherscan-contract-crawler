// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../dexs/Switch.sol";
import { IStargateRouter, IFactory, IPool } from "../interfaces/IStargateRouter.sol";
import { IStargateEthRouter } from "../interfaces/IStargateEthRouter.sol";
import "../lib/DataTypes.sol";

contract SwitchStargateSender is Switch {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    address public stargateRouter;
    address public stargateEthRouter;

    struct StargateSwapRequest {
        bytes32 id;
        bytes32 bridge;
        address srcToken;
        address bridgeToken;
        address dstToken;
        address recipient;
        uint256 srcAmount;
        uint256 bridgeDstAmount;
        uint256 estimatedDstAmount;
        uint256 minDstAmount;
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
        uint256[] dstDistribution;
        bytes dstParaswapData;
    }

    struct SwapArgsStargate {
        DataTypes.SwapInfo srcSwap;
        DataTypes.SwapInfo dstSwap;
        address payable recipient;
        address partner;
        uint256 partnerFeeRate;
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 amount;
        uint256 minSrcReturn; // min return from swap on src chain
        uint256 minDstAmount;
        uint256 bridgeDstAmount;
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        uint256 estimatedDstTokenAmount;
        uint256[] srcDistribution;
        uint256[] dstDistribution;
        uint16  dstChainId;
        bytes32 id;
        bytes32 bridge;
        bytes callTo;
        bytes srcParaswapData;
        bytes dstParaswapData;
    }

    struct TransferArgsStargate {
        address fromToken;
        address destToken;
        address payable recipient;
        address partner;
        uint256 partnerFeeRate;
        uint256 amount;
        uint256 minDstAmount;
        uint256 bridgeDstAmount;
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint16 dstChainId;
        bytes32 id;
        bytes32 bridge;
    }

    event StargateRouterSet(address stargateRouter);
    event StargateEthRouterSet(address stargateEthRouter);

    constructor(
        address _weth,
        address _otherToken,
        uint256[] memory _pathCountAndSplit,
        address[] memory _factories,
        address[] memory _switchViewAndEventAddresses,
        address _stargateRouter,
        address _stargateEthRouter,
        address _paraswapProxy,
        address _augustusSwapper,
        address _feeCollector
    ) Switch(_weth, _otherToken, _pathCountAndSplit[0], _pathCountAndSplit[1], _factories, _switchViewAndEventAddresses[0], _switchViewAndEventAddresses[1], _paraswapProxy, _augustusSwapper, _feeCollector)
        public
    {
        stargateRouter = _stargateRouter;
        stargateEthRouter = _stargateEthRouter;
    }

    function setStargateRouter(address _newStargateRouter) external onlyOwner {
        stargateRouter = _newStargateRouter;
        emit StargateRouterSet(_newStargateRouter);
    }

    function setStargateEthRouter(address _newStargateEthRouter) external onlyOwner {
        stargateEthRouter = _newStargateEthRouter;
        emit StargateEthRouterSet(_newStargateEthRouter);
    }

    function getLayerZeroFee(
        StargateSwapRequest calldata request,
        uint16 dstChainId,
        uint256 dstGasForCall,
        uint256 dstNativeAmount,
        address receiver
    )
        public
        view
        returns(uint256, uint256)
    {
        bytes memory message = abi.encode(
            StargateSwapRequest({
                id: request.id,
                bridge: request.bridge,
                srcToken: request.srcToken,
                bridgeToken: request.bridgeToken,
                dstToken: request.dstToken,
                recipient: request.recipient,
                srcAmount: request.srcAmount,
                dstDistribution: request.dstDistribution,
                dstParaswapData: request.dstParaswapData,
                paraswapUsageStatus: request.paraswapUsageStatus,
                bridgeDstAmount: request.bridgeDstAmount,
                estimatedDstAmount: request.estimatedDstAmount,
                minDstAmount: request.minDstAmount
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

    function getLayerZeroFeeWithoutMessage(
        uint16 dstChainId,
        uint256 dstGasForCall,
        uint256 dstNativeAmount,
        address receiver
    )
        external
        view
        returns(uint256, uint256)
    {

        return IStargateRouter(stargateRouter).quoteLayerZeroFee(
            dstChainId,
            1,                  // TYPE_SWAP_REMOTE on Bridge
            abi.encodePacked(receiver),
            "0x",
            IStargateRouter.lzTxObj(
                dstGasForCall,
                dstNativeAmount,
                abi.encodePacked(receiver)
            )
        );
    }

    function transferByStargate(
        TransferArgsStargate calldata transferArgs
    )
        external
        payable
        nonReentrant
    {
        IERC20(transferArgs.fromToken).universalTransferFrom(msg.sender, address(this), transferArgs.amount);

        uint256 amountAfterFee = _getAmountAfterFee(IERC20(transferArgs.fromToken), transferArgs.amount, transferArgs.partner, transferArgs.partnerFeeRate);

        (uint256 nativeFee, ) = _getLayerZeroFee("0x", transferArgs.dstChainId, transferArgs.dstGasForCall, transferArgs.dstNativeAmount, abi.encodePacked(transferArgs.recipient));
        if (IERC20(transferArgs.fromToken).isETH()) {
            require(msg.value >= transferArgs.amount + nativeFee, 'native token is not enough');

            IStargateEthRouter(stargateEthRouter).swapETH{value:msg.value}(
                transferArgs.dstChainId,                        // the minimum amount accepted out on destination
                transferArgs.recipient,                         // refund additional messageFee to this address
                abi.encodePacked(transferArgs.recipient),       // the receiver of the destination ETH
                amountAfterFee,                                 // the amount, in Local Decimals, to be swapped
                transferArgs.minDstAmount                       // the minimum amount accepted out on destination
            );
        } else {
            require(msg.value >= nativeFee, 'native token is not enough');

            address token = getTokenFromPoolId(stargateRouter, transferArgs.srcPoolId);
            if (token != transferArgs.fromToken) {
                revert("invalid token address");
            }
            IERC20(transferArgs.fromToken).safeApprove(stargateRouter, 0);
            IERC20(transferArgs.fromToken).safeApprove(stargateRouter, amountAfterFee);

            IStargateRouter(stargateRouter).swap{value:msg.value}(
                transferArgs.dstChainId,
                transferArgs.srcPoolId,                         // source pool id
                transferArgs.dstPoolId,                         // dest pool id
                transferArgs.recipient,                         // refund adddress. extra gas (if any) is returned to this address
                amountAfterFee,                                 // quantity to swap
                transferArgs.minDstAmount,                      // the min qty you would accept on the destination
                IStargateRouter.lzTxObj(
                    transferArgs.dstGasForCall,
                    transferArgs.dstNativeAmount,
                    abi.encodePacked(transferArgs.recipient)
                ),
                abi.encodePacked(transferArgs.recipient),       // the address to send the tokens to on the destination
                "0x"                                            // bytes param, if you wish to send additional payload you can abi.encode() them here
            );
        }

        _emitCrossChainTransferRequest(transferArgs, bytes32(0), amountAfterFee, msg.sender, DataTypes.SwapStatus.Succeeded);
    }

    function swapByStargate(
        SwapArgsStargate calldata swapArgs
    )
        external
        payable
        nonReentrant
    {
        IERC20(swapArgs.srcSwap.srcToken).universalTransferFrom(msg.sender, address(this), swapArgs.amount);

        uint256 returnAmount = 0;
        uint256 amountAfterFee = _getAmountAfterFee(
            IERC20(swapArgs.srcSwap.srcToken),
            swapArgs.amount,
            swapArgs.partner,
            swapArgs.partnerFeeRate
        );
        if (swapArgs.srcSwap.srcToken == swapArgs.srcSwap.dstToken) {
            returnAmount = amountAfterFee;
        } else {
            if ((swapArgs.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.OnSrcChain) ||
                (swapArgs.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.Both))
            {
                returnAmount = _swapFromParaswap(swapArgs, amountAfterFee);
            } else {
                (returnAmount, ) = _swapBeforeStargate(swapArgs, amountAfterFee);
            }
            if (IERC20(swapArgs.srcSwap.dstToken).isETH()) {
                weth.deposit{value: returnAmount}();
                weth.approve(stargateRouter, returnAmount);
            }
        }
        require(returnAmount >= swapArgs.minSrcReturn, "return amount was not enough");

        bytes memory message = abi.encode(
            StargateSwapRequest({
                id: swapArgs.id,
                bridge: swapArgs.bridge,
                srcToken: swapArgs.srcSwap.srcToken,
                bridgeToken: swapArgs.dstSwap.srcToken,
                dstToken: swapArgs.dstSwap.dstToken,
                recipient: swapArgs.recipient,
                srcAmount: returnAmount,
                dstDistribution: swapArgs.dstDistribution,
                dstParaswapData: swapArgs.dstParaswapData,
                paraswapUsageStatus: swapArgs.paraswapUsageStatus,
                bridgeDstAmount: swapArgs.bridgeDstAmount,
                estimatedDstAmount: swapArgs.estimatedDstTokenAmount,
                minDstAmount: swapArgs.minDstAmount
            })
        );

        (uint256 nativeFee, ) = _getLayerZeroFee(
            message,
            swapArgs.dstChainId,
            swapArgs.dstGasForCall,
            swapArgs.dstNativeAmount,
            swapArgs.callTo
        );

        if (IERC20(swapArgs.srcSwap.srcToken).isETH()) {
            require(msg.value >= swapArgs.amount + nativeFee, 'native token is not enough');
        } else {
            require(msg.value >= nativeFee, 'native token is not enough');
        }

        if (!IERC20(swapArgs.srcSwap.dstToken).isETH()) {
            uint256 approvedAmount = IERC20(swapArgs.srcSwap.dstToken).allowance(address(this), stargateRouter);
            if (approvedAmount < returnAmount) {
                IERC20(swapArgs.srcSwap.dstToken).safeIncreaseAllowance(stargateRouter, returnAmount - approvedAmount);
            }
        }

        IStargateRouter(stargateRouter).swap{value:nativeFee}(
            swapArgs.dstChainId,
            swapArgs.srcPoolId,                         // source pool id
            swapArgs.dstPoolId,                         // dest pool id
            swapArgs.recipient,                         // refund adddress. extra gas (if any) is returned to this address
            returnAmount,                                   // quantity to swap
            swapArgs.minDstAmount,                      // the min qty you would accept on the destination
            IStargateRouter.lzTxObj(
                swapArgs.dstGasForCall,
                swapArgs.dstNativeAmount,
                swapArgs.callTo
            ),
            swapArgs.callTo,                            // the address to send the tokens to on the destination
            message                                         // bytes param, if you wish to send additional payload you can abi.encode() them here
        );

        _emitCrossChainSwapRequest(swapArgs, bytes32(0), returnAmount, msg.sender, DataTypes.SwapStatus.Succeeded);
    }

    function getTokenFromPoolId(
        address _router,
        uint256 _poolId
    )
        private
        view
        returns (address)
    {
        address factory = IStargateRouter(_router).factory();
        address pool = IFactory(factory).getPool(_poolId);
        return IPool(pool).token();
    }

    function _swapBeforeStargate(
        SwapArgsStargate calldata transferArgs,
        uint256 amount
    )
        private
        returns
    (
        uint256 returnAmount,
        uint256 parts
    )
    {
        parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint i = 0; i < transferArgs.srcDistribution.length; i++) {
            if (transferArgs.srcDistribution[i] > 0) {
                parts += transferArgs.srcDistribution[i];
                lastNonZeroIndex = i;
            }
        }

        require(parts > 0, "invalid distribution param");

        // break function to avoid stack too deep error
        returnAmount = _swapInternalForSingleSwap(transferArgs.srcDistribution, amount, parts, lastNonZeroIndex, IERC20(transferArgs.srcSwap.srcToken), IERC20(transferArgs.srcSwap.dstToken));
        require(returnAmount > 0, "Swap failed from dex");

        switchEvent.emitSwapped(msg.sender, address(this), IERC20(transferArgs.srcSwap.srcToken), IERC20(transferArgs.srcSwap.dstToken), amount, returnAmount, 0);
    }

    function _swapFromParaswap(
        SwapArgsStargate calldata swapArgs,
        uint256 amount
    )
        private
        returns (uint256 returnAmount)
    {
        // break function to avoid stack too deep error
        returnAmount = _swapInternalWithParaSwap(IERC20(swapArgs.srcSwap.srcToken), IERC20(swapArgs.srcSwap.dstToken), amount, swapArgs.srcParaswapData);
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

    function _emitCrossChainSwapRequest(
        SwapArgsStargate calldata transferArgs,
        bytes32 transferId,
        uint256 returnAmount,
        address sender,
        DataTypes.SwapStatus status
    )
        internal
    {
        switchEvent.emitCrosschainSwapRequest(
            transferArgs.id,
            transferId,
            transferArgs.bridge,
            sender,
            transferArgs.srcSwap.srcToken,
            transferArgs.srcSwap.dstToken,
            transferArgs.dstSwap.dstToken,
            transferArgs.amount,
            returnAmount,
            transferArgs.estimatedDstTokenAmount,
            status
        );
    }

    function _emitCrossChainTransferRequest(
        TransferArgsStargate calldata transferArgs,
        bytes32 transferId,
        uint256 returnAmount,
        address sender,
        DataTypes.SwapStatus status
    )
        internal
    {
        switchEvent.emitCrosschainSwapRequest(
            transferArgs.id,
            transferId,
            transferArgs.bridge,
            sender,
            transferArgs.fromToken,
            transferArgs.fromToken,
            transferArgs.destToken,
            transferArgs.amount,
            returnAmount,
            transferArgs.bridgeDstAmount,
            status
        );
    }
}