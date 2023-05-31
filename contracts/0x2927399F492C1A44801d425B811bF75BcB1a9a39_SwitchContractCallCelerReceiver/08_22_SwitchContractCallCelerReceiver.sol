// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../dexs/Switch.sol";
import "../lib/DataTypes.sol";
import { ICallDataExecutor } from "../interfaces/ICallDataExecutor.sol";
import { ISwitchEvent } from "../interfaces/ISwitchEvent.sol";
import "sgn-v2-contracts/contracts/message/interfaces/IMessageReceiverApp.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SwitchContractCallCelerReceiver is Switch {
    address public celerMessageBus;
    address public callDataExecutor;
    using SafeERC20 for IERC20;
    using UniversalERC20 for IERC20;

    event CallDataExecutorSet(address callDataExecutor);
    event CelerMessageBusSet(address celerMessageBus);

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
        celerMessageBus = _celerMessageBus;
        callDataExecutor = _callDataExecutor;
    }

    modifier onlyMessageBus() {
        require(msg.sender == celerMessageBus, "caller is not message bus");
        _;
    }

    function setCelerMessageBus(address _newCelerMessageBus) external onlyOwner {
        celerMessageBus = _newCelerMessageBus;
        emit CelerMessageBusSet(_newCelerMessageBus);
    }

    function setCallDataExecutor(address _newCallDataExecutor) external onlyOwner {
        callDataExecutor = _newCallDataExecutor;
        emit CallDataExecutorSet(_newCallDataExecutor);
    }

    // handler function required by MsgReceiverApp
    function executeMessageWithTransfer(
        address, //sender
        address _token,
        uint256 _amount,
        uint64, //_srcChainId,
        bytes memory _message,
        address // executor
    )
        external
        payable
        onlyMessageBus
        returns (IMessageReceiverApp.ExecutionStatus)
    {
        DataTypes.ContractCallRequest memory m = abi.decode((_message), (DataTypes.ContractCallRequest));
        require(_token == m.bridgeToken, "bridged token must be the same as the first token in destination swap path");

        uint256 callAmount = m.estimatedCallAmount;
        if (m.bridgeToken != m.callToken) {
            require(_amount >= m.bridgeDstAmount, "estimated bridge token balance is insufficient");
            if (m.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.OnDestChain ||
                m.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.Both) { // When case using paraswap
                // swap token through paraswap
                _executeCallData(
                    _token,
                    augustusSwapper,
                    paraswapProxy,
                    m.callInfo.contractOutputsToken,
                    m.recipient,
                    _amount,
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
                uint256 dstAmount = _executeWithDistribution(m, _amount);
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

            _emitCrosschainContractCallDone(m, _amount, callAmount, DataTypes.ContractCallStatus.Succeeded);
        } else {
            callAmount = m.bridgeDstAmount;
            require(_amount >= callAmount, "balance is insufficient");
            _executeCallData(
                _token,
                m.callInfo.toContractAddress,
                m.callInfo.toApprovalAddress,
                m.callInfo.contractOutputsToken,
                m.recipient,
                callAmount,
                m.callInfo.toContractGasLimit,
                m.callInfo.toContractCallData
            );
            _sendToRecipient(_token, m.recipient, _amount - callAmount);
            _emitCrosschainContractCallDone(m, _amount, _amount, DataTypes.ContractCallStatus.Succeeded);
        }
        // always return true since swap failure is already handled in-place
        return IMessageReceiverApp.ExecutionStatus.Success;
    }

    // called on source chain for handling of bridge failures (bad liquidity, bad slippage, etc...)
    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message,
        address // executor
    )
        external
        payable
        onlyMessageBus
        returns (IMessageReceiverApp.ExecutionStatus)
    {
        DataTypes.ContractCallRequest memory m = abi.decode((_message), (DataTypes.ContractCallRequest));
        _sendToRecipient(_token, m.recipient, _amount);

        switchEvent.emitCrosschainContractCallRequest(
            m.id,
            bytes32(0),
            m.bridge,
            m.recipient,
            m.callInfo.toContractAddress, // contract address for contract call
            m.callInfo.toApprovalAddress, // the approval address for contract call
            m.srcToken,
            m.callToken,
            m.srcAmount,
            m.estimatedCallAmount,
            DataTypes.ContractCallStatus.Fallback
        );

        return IMessageReceiverApp.ExecutionStatus.Success;
    }

    // handler function required by MsgReceiverApp
    // called only if handleMessageWithTransfer above was reverted
    function executeMessageWithTransferFallback(
        address, // sender
        address _token, // token,
        uint256 _amount, // amount
        uint64, // _srcChainId,
        bytes memory _message,
        address // executor
    )
        external
        payable
        onlyMessageBus
        returns (IMessageReceiverApp.ExecutionStatus)
    {
        DataTypes.ContractCallRequest memory m = abi.decode((_message), (DataTypes.ContractCallRequest));
        _sendToRecipient(_token, m.recipient, _amount);

        _emitCrosschainContractCallDone(m, _amount, 0, DataTypes.ContractCallStatus.Fallback);
        // we can do in this app as the swap failures are already handled in executeMessageWithTransfer
        return IMessageReceiverApp.ExecutionStatus.Success;
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
        (status, dstAmount) = _swapInternalForCeler(srcAmount, parts, lastNonZeroIndex, m);
        _emitCrosschainSwapDone(m, srcAmount, dstAmount, status);
    }

    function _swapInternalForCeler(
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