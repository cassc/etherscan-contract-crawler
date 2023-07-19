// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../dexs/Switch.sol";
import "sgn-v2-contracts/contracts/message/libraries/MessageSenderLib.sol";
import "sgn-v2-contracts/contracts/message/libraries/MsgDataTypes.sol";
import "sgn-v2-contracts/contracts/message/interfaces/IMessageBus.sol";
import "../lib/DataTypes.sol";
import { IPriceTracker } from "../interfaces/IPriceTracker.sol";
import { ICBridge } from "../interfaces/ICBridge.sol";

contract SwitchContractCallCelerSender is Switch {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;
    address public celerMessageBus;
    address public priceTracker;
    address public nativeWrap;
    uint256 executorFee;
    uint256 claimableExecutionFee;

    struct ContractCallArgsCeler {
        DataTypes.SwapInfo srcSwap;
        DataTypes.SwapInfo dstSwap;
        address recipient;
        address callTo; // The address of the destination app contract.
        address partner;
        uint256 amount;
        uint256 expectedReturn; // expected bridge token amount on sending chain
        uint256 minReturn; // minimum amount of bridge token
        uint256 bridgeDstAmount; // estimated token amount of bridgeToken
        uint256 estimatedCallAmount; // estimated contract call amount on receiving chain
        uint256[] srcDistribution;
        uint256[] dstDistribution;
        uint64 dstChainId;
        uint64 nonce;
        uint32 bridgeSlippage;
        bytes32 id;
        bytes32 bridge;
        bytes srcParaswapData;
        bytes dstParaswapData;
        MsgDataTypes.BridgeSendType bridgeTransferType;
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
        DataTypes.ContractCallInfo callInfo;
    }

    event ExecutorFeeClaimed(uint256 amount, address receiver);
    event CelerMessageBusSet(address celerMessageBus);
    event PriceTrackerSet(address priceTracker);
    event ExecutorFeeSet(uint256 executorFee);
    event NativeWrapSet(address wrapAddress);

    constructor(
        address _weth,
        address _otherToken,
        uint256[] memory _pathCountAndSplit,
        address[] memory _factories,
        address _switchViewAddress,
        address _switchEventAddress,
        address _celerMessageBus,
        address _paraswapProxy,
        address _augustusSwapper,
        address _priceTracker
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
        celerMessageBus = _celerMessageBus;
        priceTracker = _priceTracker;
        nativeWrap = _weth;
    }

    modifier onlyMessageBus() {
        require(msg.sender == celerMessageBus, "caller is not message bus");
        _;
    }

    function setCelerMessageBus(address _celerMessageBus) external onlyOwner {
        celerMessageBus = _celerMessageBus;
        emit CelerMessageBusSet(celerMessageBus);
    }

    function setPriceTracker(address _priceTracker) external onlyOwner {
        priceTracker = _priceTracker;
        emit PriceTrackerSet(priceTracker);
    }

    function setExecutorFee(uint256 _executorFee) external onlyOwner {
        require(_executorFee > 0, "price cannot be 0");
        executorFee = _executorFee;
        emit ExecutorFeeSet(_executorFee);
    }

    function setNativeWrap(address _wrapAddress) external onlyOwner {
        nativeWrap = _wrapAddress;
        emit NativeWrapSet(nativeWrap);
    }

    function claimExecutorFee(address feeReceiver) external onlyOwner {
        payable(feeReceiver).transfer(claimableExecutionFee);
        emit ExecutorFeeClaimed(claimableExecutionFee, feeReceiver);
        claimableExecutionFee = 0;
    }

    function getAdjustedExecutorFee(uint256 dstChainId) public view returns(uint256) {
        return IPriceTracker(priceTracker).getPrice(block.chainid, dstChainId) * executorFee / 1e18;
    }

    function getSgnFeeByMessage(bytes memory message) public view returns(uint256) {
        return IMessageBus(celerMessageBus).calcFee(message);
    }

    function getSgnFeeForContractCall(
        DataTypes.ContractCallRequest calldata request
    )
        external
        view
        returns (uint256 sgnFee)
    {
        sgnFee = IMessageBus(celerMessageBus).calcFee(
            abi.encode(
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
            )
        );
    }

    function contractCallByCeler(
        ContractCallArgsCeler calldata callArgs
    )
        external
        payable
        returns (bytes32 transferId)
    {
        require(callArgs.callInfo.toApprovalAddress != address(0), "The approval address shouldn't be zero");
        IERC20(callArgs.srcSwap.srcToken).universalTransferFrom(msg.sender, address(this), callArgs.amount);

        uint256 returnAmount = 0;
        uint256 amountAfterFee = _getAmountAfterFee(IERC20(callArgs.srcSwap.srcToken), callArgs.amount, callArgs.partner);
        bool bridgeTokenIsNative = false;

        if ((IERC20(callArgs.srcSwap.srcToken).isETH() && IERC20(callArgs.srcSwap.dstToken).isETH()) ||
            (IERC20(callArgs.srcSwap.srcToken).isETH() && (callArgs.srcSwap.dstToken == nativeWrap))
        ) {
            require(nativeWrap != address(0), 'native wrap address should not be zero');
            weth.deposit{value: amountAfterFee}();
            bridgeTokenIsNative = true;
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

        uint256 adjustedExecutionFee = getAdjustedExecutorFee(callArgs.dstChainId);
        uint256 sgnFee = getSgnFeeByMessage(message);
        if (IERC20(callArgs.srcSwap.srcToken).isETH()) {
            require(msg.value >= callArgs.amount + sgnFee + adjustedExecutionFee, 'native token is not enough');
        } else {
            require(msg.value >= sgnFee + adjustedExecutionFee, 'native token is not enough');
        }

        payable(address(this)).transfer(adjustedExecutionFee);
        claimableExecutionFee += adjustedExecutionFee;

        if (callArgs.srcSwap.srcToken == callArgs.srcSwap.dstToken) {
            returnAmount = amountAfterFee;
        } else {
            if ((callArgs.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.OnSrcChain) ||
                (callArgs.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.Both)) {
                returnAmount = _swapFromParaswap(callArgs, amountAfterFee);
            } else {
                (returnAmount, ) = _swapBeforeCeler(callArgs, amountAfterFee);
            }
        }

        require(returnAmount > 0, 'The amount too small');
        //MessageSenderLib is your swiss army knife of sending messages
        transferId = MessageSenderLib.sendMessageWithTransfer(
            callArgs.callTo,
            bridgeTokenIsNative ? nativeWrap : callArgs.srcSwap.dstToken,
            returnAmount,
            callArgs.dstChainId,
            callArgs.nonce,
            callArgs.bridgeSlippage,
            message,
            callArgs.bridgeTransferType,
            celerMessageBus,
            sgnFee
        );

        _emitCrossChainContractCallRequest(
            callArgs,
            transferId,
            returnAmount,
            msg.sender,
            DataTypes.ContractCallStatus.Succeeded
        );
    }

    function _swapFromParaswap(
        ContractCallArgsCeler calldata callArgs,
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

    function _swapBeforeCeler(
        ContractCallArgsCeler calldata callArgs,
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

    function _emitCrossChainContractCallRequest(
        ContractCallArgsCeler calldata callArgs,
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