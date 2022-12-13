// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../dexs/Switch.sol";
import { IStargateRouter, IFactory, IPool } from "../interfaces/IStargateRouter.sol";
import "../lib/DataTypes.sol";

contract SwitchStargateSender is Switch {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    address public stargateRouter;

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
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
        uint256[] dstDistribution;
        bytes dstParaswapData;
    }

    struct SwapArgsStargate {
        DataTypes.SwapInfo srcSwap;
        DataTypes.SwapInfo dstSwap;
        address payable recipient;
        address partner;
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 amount;
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
    ) Switch(_weth, _otherToken, _pathCountAndSplit[0], _pathCountAndSplit[1], _factories, _switchViewAddress, _switchEventAddress, _paraswapProxy, _augustusSwapper)
        public
    {
        stargateRouter = _stargateRouter;
    }

    modifier onlyStargateRouter() {
        require(msg.sender == stargateRouter, "caller is not stargate router");
        _;
    }

    function setStargateRouter(address _newStargateRouter) external onlyOwner {
        stargateRouter = _newStargateRouter;
        emit StargateRouterSet(_newStargateRouter);
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
                estimatedDstAmount: request.estimatedDstAmount
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
        require(transferArgs.recipient == msg.sender, "recipient must be equal to caller");
        IERC20(transferArgs.fromToken).universalTransferFrom(msg.sender, address(this), transferArgs.amount);

        uint256 amountAfterFee = _getAmountAfterFee(IERC20(transferArgs.fromToken), transferArgs.amount, transferArgs.partner);
        bytes memory message = "0x";

        (uint256 nativeFee, ) = _getLayerZeroFee(message, transferArgs.dstChainId, transferArgs.dstGasForCall, transferArgs.dstNativeAmount, abi.encodePacked(transferArgs.recipient));
        if (IERC20(transferArgs.fromToken).isETH()) {
            require(msg.value >= transferArgs.amount + nativeFee, 'native token is not enough');
        } else {
            require(msg.value >= nativeFee, 'native token is not enough');

            address token = getTokenFromPoolId(stargateRouter, transferArgs.srcPoolId);
            if (token != transferArgs.fromToken) {
                revert("invalid token address");
            }
            uint256 approvedAmount = IERC20(token).allowance(address(this), stargateRouter);
            if (approvedAmount < amountAfterFee) {
                IERC20(token).safeIncreaseAllowance(stargateRouter, amountAfterFee);
            }
        }

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
            message                                         // bytes param, if you wish to send additional payload you can abi.encode() them here
        );

        _emitCrossChainTransferRequest(transferArgs, bytes32(0), amountAfterFee, msg.sender, DataTypes.SwapStatus.Succeeded);
    }

    function swapByStargate(
        SwapArgsStargate calldata transferArgs
    )
        external
        payable
        nonReentrant
    {
        require(transferArgs.recipient == msg.sender, "recipient must be equal to caller");
        IERC20(transferArgs.srcSwap.srcToken).universalTransferFrom(msg.sender, address(this), transferArgs.amount);

        uint256 returnAmount = 0;
        uint256 amountAfterFee = _getAmountAfterFee(IERC20(transferArgs.srcSwap.srcToken), transferArgs.amount, transferArgs.partner);
        if (transferArgs.srcSwap.srcToken == transferArgs.srcSwap.dstToken) {
            returnAmount = amountAfterFee;
        } else {
            if ((transferArgs.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.OnSrcChain) || (transferArgs.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.Both)) {
                returnAmount = _swapFromParaswap(transferArgs, amountAfterFee);
            } else {
                (returnAmount, ) = _swapBeforeStargate(transferArgs, amountAfterFee);
            }
        }

        bytes memory message = abi.encode(
            StargateSwapRequest({
                id: transferArgs.id,
                bridge: transferArgs.bridge,
                srcToken: transferArgs.srcSwap.srcToken,
                bridgeToken: transferArgs.dstSwap.srcToken,
                dstToken: transferArgs.dstSwap.dstToken,
                recipient: transferArgs.recipient,
                srcAmount: returnAmount,
                dstDistribution: transferArgs.dstDistribution,
                dstParaswapData: transferArgs.dstParaswapData,
                paraswapUsageStatus: transferArgs.paraswapUsageStatus,
                bridgeDstAmount: transferArgs.bridgeDstAmount,
                estimatedDstAmount: transferArgs.estimatedDstTokenAmount
            })
        );

        (uint256 nativeFee, ) = _getLayerZeroFee(message, transferArgs.dstChainId, transferArgs.dstGasForCall, transferArgs.dstNativeAmount, transferArgs.callTo);

        if (IERC20(transferArgs.srcSwap.srcToken).isETH()) {
            require(msg.value >= transferArgs.amount + nativeFee, 'native token is not enough');
        } else {
            require(msg.value >= nativeFee, 'native token is not enough');
        }

        if (!IERC20(transferArgs.srcSwap.dstToken).isETH()) {
            uint256 approvedAmount = IERC20(transferArgs.srcSwap.dstToken).allowance(address(this), stargateRouter);
            if (approvedAmount < returnAmount) {
                IERC20(transferArgs.srcSwap.dstToken).safeIncreaseAllowance(stargateRouter, returnAmount);
            }
        }

        IStargateRouter(stargateRouter).swap{value:nativeFee}(
            transferArgs.dstChainId,
            transferArgs.srcPoolId,                         // source pool id
            transferArgs.dstPoolId,                         // dest pool id
            transferArgs.recipient,                         // refund adddress. extra gas (if any) is returned to this address
            returnAmount,                                   // quantity to swap
            transferArgs.minDstAmount,                      // the min qty you would accept on the destination
            IStargateRouter.lzTxObj(
                transferArgs.dstGasForCall,
                transferArgs.dstNativeAmount,
                transferArgs.callTo
            ),
            transferArgs.callTo,                            // the address to send the tokens to on the destination
            message                                         // bytes param, if you wish to send additional payload you can abi.encode() them here
        );

        _emitCrossChainSwapRequest(transferArgs, bytes32(0), returnAmount, msg.sender, DataTypes.SwapStatus.Succeeded);
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