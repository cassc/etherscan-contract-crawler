// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../dexs/Switch.sol";
import { IStargateReceiver } from "../interfaces/IStargateReceiver.sol";
import { ICallDataExecutor } from "../interfaces/ICallDataExecutor.sol";
import "../lib/DataTypes.sol";

contract SwitchContractCallStargateReceiver is Switch, IStargateReceiver {
    using UniversalERC20 for IERC20;

    address public stargateRouter;
    address public callDataExecutor;
    uint8 public constant TYPE_SWAP_REMOTE = 1;

    event StargateRouterSet(address stargateRouter);
    event CallDataExecutorSet(address callDataExecutor);

    constructor(
        address _weth,
        address _otherToken,
        uint256[] memory _pathCountAndSplit,
        address[] memory _factories,
        address _switchViewAddress,
        address _switchEventAddress,
        address _stargateRouter,
        address _paraswapProxy,
        address _augustusSwapper,
        address _callDataExecutor
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
        callDataExecutor = _callDataExecutor;
    }

    modifier onlyStargateRouter() {
        require(msg.sender == stargateRouter, "caller is not stargate router");
        _;
    }

    function setStargateRouter(address _newStargateRouter) external onlyOwner {
        stargateRouter = _newStargateRouter;
        emit StargateRouterSet(_newStargateRouter);
    }

    function setCallDataExecutor(address _newCallDataExecutor) external onlyOwner {
        callDataExecutor = _newCallDataExecutor;
        emit CallDataExecutorSet(_newCallDataExecutor);
    }

    // STARGATE RECEIVER - the destination contract must implement this function to receive the tokens and payload
    function sgReceive(
        uint16,
        bytes memory,
        uint256,
        address token,
        uint amount,
        bytes memory payload
    )
        override
        external
        onlyStargateRouter
    {
        DataTypes.ContractCallRequest memory m = abi.decode((payload), (DataTypes.ContractCallRequest));
        require(token == m.bridgeToken, "bridged token must be the same as the first token in destination swap path");

        uint256 reserveGas = 100000;

        if(gasleft() < reserveGas) {
            _sendToRecipient(token, m.recipient, amount);
            _emitCrosschainContractCallDone(m, amount, 0, DataTypes.ContractCallStatus.Failed);
            return;
        }

        // 100000 -> exit gas
        uint256 limit = gasleft() - reserveGas;

        try
            this.remoteContractCall{gas: limit}(m, amount, token)
        {} catch Error(string memory) {
            _sendToRecipient(token, m.recipient, amount);
            _emitCrosschainContractCallDone(m, amount, 0, DataTypes.ContractCallStatus.Failed);
        } catch (bytes memory) {
            _sendToRecipient(token, m.recipient, amount);
            _emitCrosschainContractCallDone(m, amount, 0, DataTypes.ContractCallStatus.Failed);
        }
    }

    function remoteContractCall(
        DataTypes.ContractCallRequest memory m,
        uint256 amount,
        address token
    )
        external
    {
        uint256 callAmount = m.estimatedCallAmount;
        if (m.bridgeToken == m.callToken) {
            callAmount = m.bridgeDstAmount;
            require(amount >= callAmount, "balance is insufficient");
            _executeCallData(
                token,
                m.callInfo.toContractAddress,
                m.callInfo.toApprovalAddress,
                m.callInfo.contractOutputsToken,
                m.recipient,
                callAmount,
                m.callInfo.toContractGasLimit,
                m.callInfo.toContractCallData
            );
            _sendToRecipient(token, m.recipient, amount - callAmount);
            _emitCrosschainContractCallDone(m, amount, amount, DataTypes.ContractCallStatus.Succeeded);
        } else {
            require(amount >= m.bridgeDstAmount, "estimated bridge token balance is insufficient");
            if (m.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.OnDestChain ||
                m.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.Both) { // When case using paraswap
                // swap token through paraswap
                _executeCallData(
                    token,
                    augustusSwapper,
                    paraswapProxy,
                    m.callInfo.contractOutputsToken,
                    m.recipient,
                    amount,
                    0,
                    m.dstParaswapData
                );
                // execute calldata for contract call
                ICallDataExecutor(callDataExecutor).execute(
                    IERC20(m.callToken),
                    m.callInfo.toContractAddress,
                    m.callInfo.toApprovalAddress,
                    m.callInfo.contractOutputsToken,
                    m.recipient,
                    callAmount,
                    m.callInfo.toContractGasLimit,
                    m.callInfo.toContractCallData
                );
            } else {
                uint256 dstAmount = _executeWithDistribution(m, amount);
                require(dstAmount >= callAmount, "failed swapping from dex");
                // execute calldata for contract call
                _executeCallData(
                    m.callToken,
                    m.callInfo.toContractAddress,
                    m.callInfo.toApprovalAddress,
                    m.callInfo.contractOutputsToken,
                    m.recipient,
                    callAmount,
                    m.callInfo.toContractGasLimit,
                    m.callInfo.toContractCallData
                );
            }
            _emitCrosschainContractCallDone(m, amount, callAmount, DataTypes.ContractCallStatus.Succeeded);
        }
    }

    function _sendToRecipient(
        address token,
        address recipient,
        uint256 amount
    )
        internal
    {
        if (IERC20(token).isETH()) {
            payable(recipient).transfer(amount);
        } else {
            IERC20(token).universalTransfer(recipient, amount);
        }
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
            // Give approval
            IERC20(token).universalApprove(callDataExecutor, amount);
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
        DataTypes.ContractCallRequest memory m,
        uint256 srcAmount
    )
        internal
        returns (
            uint256 dstAmount
        )
    {
        DataTypes.SwapStatus status = DataTypes.SwapStatus.Succeeded;
        uint256 parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint i = 0; i < m.dstDistribution.length; i++) {
            if (m.dstDistribution[i] > 0) {
                parts += m.dstDistribution[i];
                lastNonZeroIndex = i;
            }
        }

        require(parts > 0, "invalid distribution param");
        (status, dstAmount) = _swapInternalForStargate(srcAmount, parts, lastNonZeroIndex, m);
        _emitCrosschainSwapDone(m, srcAmount, dstAmount, status);
    }

    function _swapInternalForStargate(
        uint256 amount,
        uint256 parts,
        uint256 lastNonZeroIndex,
        DataTypes.ContractCallRequest memory m // callData
    )
        internal
        returns (
            DataTypes.SwapStatus status,
            uint256 returnAmount
        )
    {
        returnAmount = _swapInternalForSingleSwap(
            m.dstDistribution,
            amount,
            parts,
            lastNonZeroIndex,
            IERC20(m.bridgeToken),
            IERC20(m.callToken)
        );

        if (returnAmount > 0) {
            status = DataTypes.SwapStatus.Succeeded;
            switchEvent.emitSwapped(
                msg.sender,
                address(this),
                IERC20(m.bridgeToken),
                IERC20(m.callToken),
                amount,
                returnAmount,
                0
            );
        } else {
            // handle swap failure, send the received token directly to recipient
            IERC20(m.bridgeToken).universalTransfer(m.recipient, amount);
            returnAmount = amount;
            status = DataTypes.SwapStatus.Fallback;
        }
    }

    function _emitCrosschainContractCallDone(
        DataTypes.ContractCallRequest memory m,
        uint256 srcAmount,
        uint256 dstAmount,
        DataTypes.ContractCallStatus status
    )
        internal
    {
        switchEvent.emitCrosschainContractCallDone(
            m.id,
            m.bridge,
            m.recipient,
            m.callInfo.toContractAddress,
            m.callInfo.toApprovalAddress,
            m.bridgeToken,
            m.callToken,
            srcAmount,
            dstAmount,
            status
        );
    }

    function _emitCrosschainSwapDone(
        DataTypes.ContractCallRequest memory m,
        uint256 srcAmount,
        uint256 dstAmount,
        DataTypes.SwapStatus status
    )
        internal
    {
        switchEvent.emitCrosschainSwapDone(
            m.id,
            m.bridge,
            m.recipient,
            m.bridgeToken,
            m.callToken,
            srcAmount,
            dstAmount,
            status
        );
    }
}