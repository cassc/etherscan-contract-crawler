// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../dexs/Switch.sol";
import "sgn-v2-contracts/contracts/message/interfaces/IMessageReceiverApp.sol";
import "../lib/DataTypes.sol";

contract SwitchCelerReceiver is Switch {
    address public celerMessageBus;
    using UniversalERC20 for IERC20;

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

    constructor(
        address _weth,
        address _otherToken,
        uint256 _pathCount,
        uint256 _pathSplit,
        address[] memory _factories,
        address _switchViewAddress,
        address _switchEventAddress,
        address _celerMessageBus,
        address _paraswapProxy,
        address _augustusSwapper
    ) Switch(_weth, _otherToken, _pathCount, _pathSplit, _factories, _switchViewAddress, _switchEventAddress, _paraswapProxy, _augustusSwapper) public {
        celerMessageBus = _celerMessageBus;
    }

    modifier onlyMessageBus() {
        require(msg.sender == celerMessageBus, "caller is not message bus");
        _;
    }

    function setCelerMessageBus(address _newCelerMessageBus) external onlyOwner {
        celerMessageBus = _newCelerMessageBus;
    }

    // handler function required by MsgReceiverApp
    function executeMessageWithTransfer(
        address, //sender
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes memory _message,
        address // executor
    )
        external
        payable
        onlyMessageBus
        returns (IMessageReceiverApp.ExecutionStatus)
    {
        CelerSwapRequest memory m = abi.decode((_message), (CelerSwapRequest));
        require(_token == m.bridgeToken, "bridged token must be the same as the first token in destination swap path");

        if (m.bridgeToken == m.dstToken) {
            IERC20(m.bridgeToken).universalTransfer(m.recipient, _amount);
            _emitCrosschainSwapDone(m, _amount, _amount, DataTypes.SwapStatus.Succeeded);
        } else {
            if (m.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.OnDestChain || m.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.Both) { // When case using paraswap
                if (_amount >= m.bridgeDstAmount) {
                    _callParaswap(IERC20(_token), m.bridgeDstAmount, m.dstParaswapData);
                    IERC20(_token).universalTransfer(m.recipient,  _amount - m.bridgeDstAmount);
                    _emitCrosschainSwapDone(m, m.bridgeDstAmount, m.estimatedDstAmount, DataTypes.SwapStatus.Succeeded);
                } else {
                    _executeWithDistribution(m, _amount);
                }
            } else {
                _executeWithDistribution(m, _amount);
            }
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
        CelerSwapRequest memory m = abi.decode((_message), (CelerSwapRequest));

        if (IERC20(_token).isETH()) {
            payable(m.recipient).transfer(_amount);
        } else {
            IERC20(_token).universalTransfer(m.recipient, _amount);
        }

        switchEvent.emitCrosschainSwapRequest(
            m.id,
            bytes32(0),
            m.bridge,
            m.recipient,
            m.srcToken,
            _token,
            m.dstToken,
            m.srcAmount,
            _amount,
            m.estimatedDstAmount,
            DataTypes.SwapStatus.Fallback
        );

        return IMessageReceiverApp.ExecutionStatus.Success;
    }

    // handler function required by MsgReceiverApp
    // called only if handleMessageWithTransfer above was reverted
    function executeMessageWithTransferFallback(
        address, // sender
        address _token, // token,
        uint256 _amount, // amount
        uint64 _srcChainId,
        bytes memory _message,
        address // executor
    )
        external
        payable
        onlyMessageBus
        returns (IMessageReceiverApp.ExecutionStatus)
    {
        CelerSwapRequest memory m = abi.decode((_message), (CelerSwapRequest));
        if (IERC20(_token).isETH()) {
            payable(m.recipient).transfer(_amount);
        } else {
            IERC20(_token).universalTransfer(m.recipient, _amount);
        }
        _emitCrosschainSwapDone(m, _amount, 0, DataTypes.SwapStatus.Fallback);
        // we can do in this app as the swap failures are already handled in executeMessageWithTransfer
        return IMessageReceiverApp.ExecutionStatus.Success;
    }

    function _swapInternalForCeler(
        uint256 amount,
        uint256 parts,
        uint256 lastNonZeroIndex,
        CelerSwapRequest memory m // callData
    )
        internal
        returns (
            DataTypes.SwapStatus status,
            uint256 returnAmount
        )
    {
        returnAmount = _swapInternalForSingleSwap(m.dstDistribution, amount, parts, lastNonZeroIndex, IERC20(m.bridgeToken), IERC20(m.dstToken));
        if (returnAmount > 0) {
            IERC20(m.dstToken).universalTransfer(m.recipient, returnAmount);
            status = DataTypes.SwapStatus.Succeeded;
            switchEvent.emitSwapped(msg.sender, address(this), IERC20(m.bridgeToken), IERC20(m.dstToken), amount, returnAmount, 0);
        } else {
            // handle swap failure, send the received token directly to recipient
            IERC20(m.bridgeToken).universalTransfer(m.recipient, amount);
            returnAmount = amount;
            status = DataTypes.SwapStatus.Fallback;
        }
    }

    function _emitCrosschainSwapDone(
        CelerSwapRequest memory m,
        uint256 srcAmount,
        uint256 dstAmount,
        DataTypes.SwapStatus status
    )
        internal
    {
        switchEvent.emitCrosschainSwapDone(m.id, m.bridge, m.recipient, m.bridgeToken, m.dstToken, srcAmount, dstAmount, status);
    }

    function _executeWithDistribution(
        CelerSwapRequest memory m,
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
}