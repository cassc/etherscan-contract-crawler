// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../dexs/Switch.sol";
import "sgn-v2-contracts/contracts/message/libraries/MessageSenderLib.sol";
import "sgn-v2-contracts/contracts/message/libraries/MsgDataTypes.sol";
import "sgn-v2-contracts/contracts/message/interfaces/IMessageBus.sol";
import "../lib/DataTypes.sol";
import { IPriceTracker } from "../interfaces/IPriceTracker.sol";
import { ICBridge } from "../interfaces/ICBridge.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SwitchCelerSender is Switch {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;
    address public celerMessageBus;
    address public cBridge;
    address public priceTracker;
    uint256 executorFee;
    uint256 claimableExecutionFee;

    struct CelerSwapRequest {
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

    struct SwapArgsCeler {
        DataTypes.SwapInfo srcSwap;
        DataTypes.SwapInfo dstSwap;
        address recipient;
        address callTo; // The address of the destination app contract.
        address partner;
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
        uint256 amount;
        uint256 expectedReturn; // expected bridge token amount on sending chain
        uint256 minReturn; // minimum amount of bridge token
        uint256 bridgeDstAmount; // estimated token amount of bridgeToken
        uint256 estimatedDstTokenAmount; // estimated dest token amount on receiving chain
        uint256[] srcDistribution;
        uint256[] dstDistribution;
        uint16 dstChainId;
        uint64 nonce;
        uint32 bridgeSlippage;
        bytes32 id;
        bytes32 bridge;
        bytes srcParaswapData;
        bytes dstParaswapData;
    }

    struct TransferArgsCeler {
        address fromToken;
        address destToken;
        address recipient;
        address partner;
        uint256 amount;
        uint256 bridgeDstAmount;
        uint16 dstChainId;
        uint64 nonce;
        uint32 bridgeSlippage;
        bytes32 id;
        bytes32 bridge;
    }

    event ExecutorFeeClaimed(uint256 amount, address receiver);
    event CelerMessageBusSet(address celerMessageBus);
    event CBridgeSet(address cBridge);
    event PriceTrackerSet(address priceTracker);
    event ExecutorFeeSet(uint256 executorFee);

    constructor(
        address _weth,
        address _otherToken,
        uint256[] memory _pathCountAndSplit,
        address[] memory _factories,
        address _switchViewAddress,
        address _switchEventAddress,
        address _celerMessageBus,
        address _cBridge,
        address _paraswapProxy,
        address _augustusSwapper,
        address _priceTracker
    ) Switch(_weth, _otherToken, _pathCountAndSplit[0], _pathCountAndSplit[1], _factories, _switchViewAddress, _switchEventAddress, _paraswapProxy, _augustusSwapper)
        public
    {
        celerMessageBus = _celerMessageBus;
        cBridge = _cBridge;
        priceTracker = _priceTracker;
    }

    modifier onlyMessageBus() {
        require(msg.sender == celerMessageBus, "caller is not message bus");
        _;
    }

    function setCelerMessageBus(address _celerMessageBus) external onlyOwner {
        celerMessageBus = _celerMessageBus;
        emit CelerMessageBusSet(celerMessageBus);
    }

    function cBridgeSet(address _cBridge) external onlyOwner {
        cBridge = _cBridge;
        emit CelerMessageBusSet(cBridge);
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

    function getSgnFee(
        bytes32 id,
        bytes32 bridge,
        address srcToken, // source token of sending chain
        address bridgeToken, // bridge token of receiving chain
        address dstToken, // destination token of receiving chain
        address recipient,
        uint256 srcAmount,
        uint256 bridgeDstAmount,
        uint256 estimatedDstAmount,
        DataTypes.ParaswapUsageStatus paraswapUsageStatus,
        uint256[] memory dstDistribution,
        bytes memory dstParaswapData // calldata from paraswap on destination chain
    )
        external
        view
        returns (uint256 sgnFee)
    {

        bytes memory message = abi.encode(
            CelerSwapRequest({
                id: id,
                bridge: bridge,
                srcToken: srcToken,
                bridgeToken: bridgeToken,
                dstToken: dstToken,
                recipient: recipient,
                srcAmount: srcAmount,
                dstDistribution: dstDistribution,
                bridgeDstAmount: bridgeDstAmount,
                estimatedDstAmount: estimatedDstAmount,
                paraswapUsageStatus: paraswapUsageStatus,
                dstParaswapData: dstParaswapData
            })
        );

        sgnFee = IMessageBus(celerMessageBus).calcFee(message);
    }

    function transferByCeler(
        TransferArgsCeler calldata transferArgs
    )
        external
        payable
        nonReentrant
        returns (bytes32 transferId)
    {
        require(transferArgs.recipient == msg.sender, "recipient must be equal to caller");
        require(transferArgs.amount > 0, "The amount must be greater than zero");
        require(block.chainid != transferArgs.dstChainId, "Cannot bridge to same network");

        IERC20(transferArgs.fromToken).universalTransferFrom(msg.sender, address(this), transferArgs.amount);
        uint256 amountAfterFee = _getAmountAfterFee(IERC20(transferArgs.fromToken), transferArgs.amount, transferArgs.partner);

        bool isNative = IERC20(transferArgs.fromToken).isETH();
        if (isNative) {
            ICBridge(cBridge).sendNative{ value: amountAfterFee }(
                transferArgs.recipient,
                amountAfterFee,
                transferArgs.dstChainId,
                transferArgs.nonce,
                transferArgs.bridgeSlippage
            );
        } else {
            // Give cbridge approval
            uint256 approvedAmount = IERC20(transferArgs.fromToken).allowance(address(this), cBridge);
            if (approvedAmount < amountAfterFee) {
                IERC20(transferArgs.fromToken).safeIncreaseAllowance(cBridge, amountAfterFee - approvedAmount);
            }

            ICBridge(cBridge).send(
                transferArgs.recipient,
                transferArgs.fromToken,
                amountAfterFee,
                transferArgs.dstChainId,
                transferArgs.nonce,
                transferArgs.bridgeSlippage
            );
        }

        bytes32 transferId = keccak256(
            abi.encodePacked(
                address(this),
                transferArgs.recipient,
                transferArgs.fromToken,
                amountAfterFee,
                transferArgs.dstChainId,
                transferArgs.nonce,
                uint64(block.chainid)
            )
        );
        _emitCrossChainTransferRequest(transferArgs, transferId, amountAfterFee, msg.sender, DataTypes.SwapStatus.Succeeded);
    }

    function swapByCeler(
        SwapArgsCeler calldata transferArgs
    )
        external
        payable
        nonReentrant
        returns (bytes32 transferId)
    {
        require(transferArgs.recipient == msg.sender, "recipient must be equal to caller");
        require(transferArgs.expectedReturn >= transferArgs.minReturn, "expectedReturn must be equal or larger than minReturn");
        IERC20(transferArgs.srcSwap.srcToken).universalTransferFrom(msg.sender, address(this), transferArgs.amount);

        uint256 returnAmount = 0;
        uint256 amountAfterFee = _getAmountAfterFee(IERC20(transferArgs.srcSwap.srcToken), transferArgs.amount, transferArgs.partner);

        bytes memory message = abi.encode(
            CelerSwapRequest({
                id: transferArgs.id,
                bridge: transferArgs.bridge,
                srcToken: transferArgs.srcSwap.srcToken,
                bridgeToken: transferArgs.dstSwap.srcToken,
                dstToken: transferArgs.dstSwap.dstToken,
                recipient: transferArgs.recipient,
                srcAmount: amountAfterFee,
                dstDistribution: transferArgs.dstDistribution,
                dstParaswapData: transferArgs.dstParaswapData,
                paraswapUsageStatus: transferArgs.paraswapUsageStatus,
                bridgeDstAmount: transferArgs.bridgeDstAmount,
                estimatedDstAmount: transferArgs.estimatedDstTokenAmount
            })
        );

        uint256 adjustedExecutionFee = getAdjustedExecutorFee(transferArgs.dstChainId);
        uint256 sgnFee = getSgnFeeByMessage(message);
        if (IERC20(transferArgs.srcSwap.srcToken).isETH()) {
            require(msg.value >= transferArgs.amount + sgnFee + adjustedExecutionFee, 'native token is not enough');
        } else {
            require(msg.value >= sgnFee + adjustedExecutionFee, 'native token is not enough');
        }

        payable(address(this)).transfer(adjustedExecutionFee);
        claimableExecutionFee += adjustedExecutionFee;

        if (transferArgs.srcSwap.srcToken == transferArgs.srcSwap.dstToken) {
            returnAmount = amountAfterFee;
        } else {
            if ((transferArgs.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.OnSrcChain) || (transferArgs.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.Both)) {
                returnAmount = _swapFromParaswap(transferArgs, amountAfterFee);
            } else {
                (returnAmount, ) = _swapBeforeCeler(transferArgs, amountAfterFee);
            }
        }

        require(returnAmount > 0, 'The amount too small');

        //MessageSenderLib is your swiss army knife of sending messages
        transferId = MessageSenderLib.sendMessageWithTransfer(
            transferArgs.callTo,
            transferArgs.srcSwap.dstToken,
            returnAmount,
            transferArgs.dstChainId,
            transferArgs.nonce,
            transferArgs.bridgeSlippage,
            message,
            MsgDataTypes.BridgeSendType.Liquidity,
            celerMessageBus,
            sgnFee
        );

        _emitCrossChainSwapRequest(transferArgs, transferId, returnAmount, msg.sender, DataTypes.SwapStatus.Succeeded);
    }

    function _swapFromParaswap(
        SwapArgsCeler calldata swapArgs,
        uint256 amount
    )
        private
        returns (uint256 returnAmount)
    {
        // break function to avoid stack too deep error
        returnAmount = _swapInternalWithParaSwap(IERC20(swapArgs.srcSwap.srcToken), IERC20(swapArgs.srcSwap.dstToken), amount, swapArgs.srcParaswapData);
    }

    function _swapBeforeCeler(SwapArgsCeler calldata transferArgs, uint256 amount) private returns (uint256 returnAmount, uint256 parts) {
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

    function _emitCrossChainSwapRequest(SwapArgsCeler calldata transferArgs, bytes32 transferId, uint256 returnAmount, address sender, DataTypes.SwapStatus status) internal {
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

    function _emitCrossChainTransferRequest(TransferArgsCeler calldata transferArgs, bytes32 transferId, uint256 returnAmount, address sender, DataTypes.SwapStatus status) internal {
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