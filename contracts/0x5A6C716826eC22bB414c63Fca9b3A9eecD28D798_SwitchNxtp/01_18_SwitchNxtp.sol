// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../dexs/Switch.sol";
import { ITransactionManager } from "../interfaces/ITransactionManager.sol";
import "../lib/DataTypes.sol";

contract SwitchNxtp is Switch {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    struct SwapArgsNxtp {
        DataTypes.SwapInfo srcSwap;
        DataTypes.SwapInfo dstSwap;
        address recipient;
        address partner;
        uint256 amount;
        uint256 expectedReturn;
        uint256 minReturn;
        uint256 expiry;
        uint256 estimatedDstTokenAmount;
        uint64 dstChainId;
        uint256[] distribution;
        bytes32 id;
        bytes32 bridge;
        ITransactionManager.InvariantTransactionData invariantData;
    }

    struct TransferArgsNxtp {
        address fromToken;
        address destToken;
        address recipient;
        address partner;
        uint256 amount;
        uint256 bridgeDstAmount;
        uint256 expiry;
        uint64 dstChainId;
        bytes32 id;
        bytes32 bridge;
        ITransactionManager.InvariantTransactionData invariantData;
    }

    ITransactionManager private transactionManager;
    address private transactionManagerAddress;

    constructor(
        address _weth,
        address _otherToken,
        uint256 _pathCount,
        uint256 _pathSplit,
        address[] memory _factories,
        address _switchViewAddress,
        address _switchEventAddress,
        address _paraswapProxy,
        address _augustusSwapper,
        address _transactionManagerAddress
    ) Switch(_weth, _otherToken, _pathCount, _pathSplit, _factories, _switchViewAddress, _switchEventAddress, _paraswapProxy, _augustusSwapper)
        public
    {
        transactionManagerAddress = _transactionManagerAddress;
        transactionManager = ITransactionManager(_transactionManagerAddress);
    }

    function setTransactionManager(address _newTransactionManager) external onlyOwner {
        transactionManagerAddress = _newTransactionManager;
    }

    function transferByNxtp(
        TransferArgsNxtp calldata transferArgs,
        bytes calldata encryptedCallData,
        bytes calldata encodedBid,
        bytes calldata bidSignature
    )
        external
        payable
        nonReentrant
        returns (ITransactionManager.TransactionData memory)
    {
        require(transferArgs.recipient == msg.sender, "recipient must be equal to caller");
        require(transferArgs.invariantData.receivingAddress == msg.sender, "recipient must be equal to caller");

        IERC20(transferArgs.fromToken).universalTransferFrom(msg.sender, address(this), transferArgs.amount);
        uint256 amountAfterFee = _getAmountAfterFee(IERC20(transferArgs.fromToken), transferArgs.amount, transferArgs.partner);

        bool native = IERC20(transferArgs.fromToken).isETH();
        if (!native) {
            uint256 approvedAmount = IERC20(transferArgs.fromToken).allowance(address(this), transactionManagerAddress);
            if (approvedAmount < amountAfterFee) {
                IERC20(transferArgs.fromToken).safeIncreaseAllowance(transactionManagerAddress, amountAfterFee);
            }
        }

        _emitCrossChainTransferRequest(transferArgs, amountAfterFee, msg.sender);

        return transactionManager.prepare(ITransactionManager.PrepareArgs({
                invariantData: transferArgs.invariantData,
                amount: amountAfterFee,
                expiry: transferArgs.expiry,
                encryptedCallData: encryptedCallData,
                encodedBid: encodedBid,
                bidSignature: bidSignature,
                encodedMeta: "0x"
            })
        );
    }

    function swapByNxtp(
        SwapArgsNxtp calldata transferArgs,
        bytes calldata encryptedCallData,
        bytes calldata encodedBid,
        bytes calldata bidSignature
    )
        external
        payable
        nonReentrant
        returns (ITransactionManager.TransactionData memory)
    {
        require(transferArgs.recipient == msg.sender, "recipient must be equal to caller");
        require(transferArgs.invariantData.receivingAddress == msg.sender, "recipient must be equal to caller");
        require(transferArgs.expectedReturn >= transferArgs.minReturn, "expectedReturn must be equal or larger than minReturn");

        IERC20(transferArgs.srcSwap.srcToken).universalTransferFrom(msg.sender, address(this), transferArgs.amount);
        uint256 returnAmount = 0;
        uint256 amountAfterFee = _getAmountAfterFee(IERC20(transferArgs.srcSwap.srcToken), transferArgs.amount, transferArgs.partner);

        // check fromToken is same or not destToken
        if (transferArgs.srcSwap.srcToken == transferArgs.srcSwap.dstToken) {
            returnAmount = amountAfterFee;
        } else {
            returnAmount = _swapBeforeNxtp(transferArgs, amountAfterFee);
        }

        if (returnAmount > 0) {
            uint256 approvedAmount = IERC20(transferArgs.srcSwap.dstToken).allowance(address(this), transactionManagerAddress);
            if (approvedAmount < returnAmount) {
                IERC20(transferArgs.srcSwap.dstToken).safeIncreaseAllowance(transactionManagerAddress, returnAmount);
            }

            _emitCrossChainSwapRequest(transferArgs, returnAmount, msg.sender);

            return transactionManager.prepare(ITransactionManager.PrepareArgs({
                    invariantData: transferArgs.invariantData,
                    amount: returnAmount,
                    expiry: transferArgs.expiry,
                    encryptedCallData: encryptedCallData,
                    encodedBid: encodedBid,
                    bidSignature: bidSignature,
                    encodedMeta: "Ox"
                })
            );
        } else {
            IERC20(transferArgs.srcSwap.srcToken).universalTransferFrom(address(this), msg.sender, transferArgs.amount);
            revert("Swap failed from dex");
        }
    }

    function swapByNxtpWithParaswap(
        SwapArgsNxtp calldata transferArgs,
        bytes calldata paraswapData,
        bytes calldata encryptedCallData,
        bytes calldata encodedBid,
        bytes calldata bidSignature
    )
        external
        payable
        nonReentrant
        returns (ITransactionManager.TransactionData memory)
    {
        require(transferArgs.recipient == msg.sender, "recipient must be equal to caller");
        require(transferArgs.invariantData.receivingAddress == msg.sender, "recipient must be equal to caller");
        require(transferArgs.expectedReturn >= transferArgs.minReturn, "expectedReturn must be equal or larger than minReturn");

        IERC20(transferArgs.srcSwap.srcToken).universalTransferFrom(msg.sender, address(this), transferArgs.amount);
        uint256 returnAmount = 0;
        // check fromToken is same or not destToken
        if (transferArgs.srcSwap.srcToken == transferArgs.srcSwap.dstToken) {
            returnAmount = transferArgs.amount;
        } else {
            returnAmount = _swapFromParaswap(transferArgs, paraswapData);
        }

        if (returnAmount > 0) {
            uint256 approvedAmount = IERC20(transferArgs.srcSwap.dstToken).allowance(address(this), transactionManagerAddress);
            if (approvedAmount < returnAmount) {
                IERC20(transferArgs.srcSwap.dstToken).safeIncreaseAllowance(transactionManagerAddress, returnAmount);
            }

            _emitCrossChainSwapRequest(transferArgs, returnAmount, msg.sender);

            return transactionManager.prepare(ITransactionManager.PrepareArgs({
                invariantData: transferArgs.invariantData,
                amount: returnAmount,
                expiry: transferArgs.expiry,
                encryptedCallData: encryptedCallData,
                encodedBid: encodedBid,
                bidSignature: bidSignature,
                encodedMeta: "Ox"
                })
            );
        } else {
            IERC20(transferArgs.srcSwap.srcToken).universalTransferFrom(address(this), msg.sender, transferArgs.amount);
            revert("Swap failed from dex");
        }
    }

    function _swapBeforeNxtp(SwapArgsNxtp calldata transferArgs, uint256 amount) private returns (uint256 returnAmount) {
        uint256 parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint i = 0; i < transferArgs.distribution.length; i++) {
            if (transferArgs.distribution[i] > 0) {
                parts += transferArgs.distribution[i];
                lastNonZeroIndex = i;
            }
        }

        require(parts > 0, "invalid distribution param");
        returnAmount = _swapInternalForSingleSwap(transferArgs.distribution, amount, parts, lastNonZeroIndex, IERC20(transferArgs.srcSwap.srcToken), IERC20(transferArgs.srcSwap.dstToken));
        switchEvent.emitSwapped(msg.sender, address(this), IERC20(transferArgs.srcSwap.srcToken), IERC20(transferArgs.srcSwap.dstToken), amount, returnAmount, 0);
    }

    function _swapFromParaswap(
        SwapArgsNxtp calldata transferArgs,
        bytes memory callData
    )
        private
        returns (uint256 returnAmount)
    {
        // break function to avoid stack too deep error
        returnAmount = _swapInternalWithParaSwap(IERC20(transferArgs.srcSwap.srcToken), IERC20(transferArgs.srcSwap.dstToken), transferArgs.amount, callData);
    }

    function _emitCrossChainSwapRequest(SwapArgsNxtp calldata transferArgs, uint256 returnAmount, address sender) internal {
        switchEvent.emitCrosschainSwapRequest(
            transferArgs.id,
            transferArgs.invariantData.transactionId,
            transferArgs.bridge,
            sender,
            transferArgs.srcSwap.srcToken,
            transferArgs.srcSwap.dstToken,
            transferArgs.dstSwap.dstToken,
            transferArgs.amount,
            returnAmount,
            transferArgs.estimatedDstTokenAmount,
            DataTypes.SwapStatus.Succeeded
        );
    }

    function _emitCrossChainTransferRequest(TransferArgsNxtp calldata transferArgs, uint256 returnAmount, address sender) internal {
        switchEvent.emitCrosschainSwapRequest(
            transferArgs.id,
            transferArgs.invariantData.transactionId,
            transferArgs.bridge,
            sender,
            transferArgs.fromToken,
            transferArgs.fromToken,
            transferArgs.destToken,
            transferArgs.amount,
            returnAmount,
            transferArgs.bridgeDstAmount,
            DataTypes.SwapStatus.Succeeded
        );
    }
}