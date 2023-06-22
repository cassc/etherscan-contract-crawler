// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../dexs/Switch.sol";
import { ICallDataExecutor } from "../interfaces/ICallDataExecutor.sol";
import "../lib/DataTypes.sol";

contract SwitchContractCall is Switch {
    address public callDataExecutor;
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;
    event CallDataExecutorSet(address callDataExecutor);

    struct ContractCallArgs {
        address fromToken;
        address callToken;
        uint256 amount;
        uint256 callAmount;
        uint256 minReturn;
        address recipient;
        uint256[] distribution;
        address partner;
        uint256 partnerFeeRate;
        bytes32 id;
        bytes srcParaswapData;
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
        DataTypes.ContractCallInfo callInfo;
    }

    constructor(
        address _weth,
        address _otherToken,
        uint256[] memory _pathCountAndSplit,
        address[] memory _factories,
        address _switchViewAddress,
        address _switchEventAddress,
        address _paraswapProxy,
        address _augustusSwapper,
        address _callDataExecutor,
        address _feeCollector
    ) Switch(
        _weth,
        _otherToken,
        _pathCountAndSplit[0],
        _pathCountAndSplit[1],
        _factories,
        _switchViewAddress,
        _switchEventAddress,
        _paraswapProxy,
        _augustusSwapper,
        _feeCollector
    )
        public
    {
        callDataExecutor = _callDataExecutor;
    }

    function setCallDataExecutor(address _newCallDataExecutor) external onlyOwner {
        callDataExecutor = _newCallDataExecutor;
        emit CallDataExecutorSet(_newCallDataExecutor);
    }

    function contractCall(
        ContractCallArgs calldata callArgs
    )
        external
        payable
        nonReentrant
    {
        IERC20(callArgs.fromToken).universalTransferFrom(msg.sender, address(this), callArgs.amount);

        uint256 returnAmount = 0;
        uint256 amountAfterFee = _getAmountAfterFee(IERC20(callArgs.fromToken), callArgs.amount, callArgs.partner, callArgs.partnerFeeRate);

        if (callArgs.fromToken == callArgs.callToken) {
            _executeCallData(
                callArgs.fromToken,
                callArgs.callInfo.toContractAddress,
                callArgs.callInfo.toApprovalAddress,
                callArgs.callInfo.contractOutputsToken,
                callArgs.recipient,
                callArgs.callAmount,
                callArgs.callInfo.toContractGasLimit,
                callArgs.callInfo.toContractCallData
            );
            _sendToRecipient(callArgs.fromToken, callArgs.recipient, amountAfterFee - callArgs.callAmount);
        } else {
            if (callArgs.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.OnSrcChain)
            {
                // swap token through paraswap
                _executeCallData(
                    callArgs.fromToken,
                    augustusSwapper,
                    paraswapProxy,
                    callArgs.callInfo.contractOutputsToken,
                    callArgs.recipient,
                    amountAfterFee,
                    0,
                    callArgs.srcParaswapData
                );
                // execute calldata for contract call
                ICallDataExecutor(callDataExecutor).execute(
                    IERC20(callArgs.callToken),
                    callArgs.callInfo.toContractAddress,
                    callArgs.callInfo.toApprovalAddress,
                    callArgs.callInfo.contractOutputsToken,
                    callArgs.recipient,
                    callArgs.callAmount,
                    callArgs.callInfo.toContractGasLimit,
                    callArgs.callInfo.toContractCallData
                );
            } else {
                returnAmount = _executeWithDistribution(callArgs, amountAfterFee);
                require(returnAmount >= callArgs.callAmount, "failed swapping from dex");
                // execute calldata for contract call
                _executeCallData(
                    callArgs.callToken,
                    callArgs.callInfo.toContractAddress,
                    callArgs.callInfo.toApprovalAddress,
                    callArgs.callInfo.contractOutputsToken,
                    callArgs.recipient,
                    callArgs.callAmount,
                    callArgs.callInfo.toContractGasLimit,
                    callArgs.callInfo.toContractCallData
                );
                // send the remain amount to the recipient.
                _sendToRecipient(callArgs.callToken, callArgs.recipient, returnAmount - callArgs.callAmount);
            }
        }
        _emitSingleChainContractCallDone(
            callArgs,
            amountAfterFee,
            callArgs.callAmount,
            DataTypes.ContractCallStatus.Succeeded
        );
    }

    function _sendToRecipient(
        address token,
        address recipient,
        uint256 amount
    )
        internal
    {
        if (IERC20(token).isETH()) {
            if (address(this).balance >= amount)
                payable(recipient).transfer(amount);
        } else {
            if (IERC20(token).balanceOf(address(this)) >= amount)
                IERC20(token).universalTransfer(recipient, amount);
        }
    }

    function _emitSingleChainContractCallDone(
        ContractCallArgs memory callArgs,
        uint256 fromAmount,
        uint256 callAmount,
        DataTypes.ContractCallStatus status
    )
        internal
    {
        switchEvent.emitSingleChainContractCallDone(
            callArgs.recipient,
            callArgs.callInfo.toContractAddress,
            callArgs.callInfo.toApprovalAddress,
            callArgs.fromToken,
            callArgs.callToken,
            fromAmount,
            callAmount,
            status
        );
    }

    function _executeCallData(
        address token,
        address callTo,
        address toApprovalAddress,
        address contractOutputsToken,
        address recipient,
        uint256 amount,
        uint256 toContractGasLimit,
        bytes memory callData
    )
        internal
    {
        if (IERC20(token).isETH()) {
            IERC20(token).universalTransfer(callDataExecutor, amount);
        } else {
            IERC20(token).universalTransfer(callDataExecutor, amount);
        }

        ICallDataExecutor(callDataExecutor).execute(
            IERC20(token),
            callTo,
            toApprovalAddress,
            contractOutputsToken,
            recipient,
            amount,
            toContractGasLimit,
            callData
        );
    }

    function _executeWithDistribution(
        ContractCallArgs calldata callArgs,
        uint256 amount
    )
        internal
        returns (
            uint256 dstAmount
        )
    {
        DataTypes.SwapStatus status = DataTypes.SwapStatus.Succeeded;
        uint256 parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint i = 0; i < callArgs.distribution.length; i++) {
            if (callArgs.distribution[i] > 0) {
                parts += callArgs.distribution[i];
                lastNonZeroIndex = i;
            }
        }

        require(parts > 0, "invalid distribution param");
        dstAmount = _swapInternal(amount, parts, lastNonZeroIndex, callArgs);
    }

    function _swapInternal(
        uint256 amount,
        uint256 parts,
        uint256 lastNonZeroIndex,
        ContractCallArgs memory callArgs
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        returnAmount = _swapInternalForSingleSwap(
            callArgs.distribution,
            amount,
            parts,
            lastNonZeroIndex,
            IERC20(callArgs.fromToken),
            IERC20(callArgs.callToken)
        );

        require(returnAmount >= callArgs.minReturn, 'The amount too small');
    }
}