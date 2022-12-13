// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../dexs/Switch.sol";
import { IStargateReceiver } from "../interfaces/IStargateReceiver.sol";
import "../lib/DataTypes.sol";

contract SwitchStargateReceiver is Switch, IStargateReceiver {
    using UniversalERC20 for IERC20;

    address public stargateRouter;
    uint8 public constant TYPE_SWAP_REMOTE = 1;

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

    event StargateRouterSet(address stargateRouter);

    constructor(
        address _weth,
        address _otherToken,
        uint256 _pathCount,
        uint256 _pathSplit,
        address[] memory _factories,
        address _switchViewAddress,
        address _switchEventAddress,
        address _stargateRouter,
        address _paraswapProxy,
        address _augustusSwapper
    ) Switch(_weth, _otherToken, _pathCount, _pathSplit, _factories, _switchViewAddress, _switchEventAddress, _paraswapProxy, _augustusSwapper)
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
        StargateSwapRequest memory m = abi.decode((payload), (StargateSwapRequest));
        require(token == m.bridgeToken, "bridged token must be the same as the first token in destination swap path");

        uint256 reserveGas = 100000;
        bool failed;

        if(gasleft() < reserveGas) {
            _sendToRecipient(token, m.recipient, amount);
            _emitCrosschainSwapDone(m, amount, 0, DataTypes.SwapStatus.Failed);
            return;
        }

        // 100000 -> exit gas
        uint256 limit = gasleft() - reserveGas;

        if (m.bridgeToken == m.dstToken) {
            _sendToRecipient(m.bridgeToken, m.recipient, amount);
            _emitCrosschainSwapDone(m, amount, amount, DataTypes.SwapStatus.Succeeded);
        } else {
            try
                this.remoteSwap{gas: limit}(m, amount, token)
            {} catch Error(string memory) {
                _sendToRecipient(token, m.recipient, amount);
                _emitCrosschainSwapDone(m, amount, 0, DataTypes.SwapStatus.Failed);
            } catch (bytes memory) {
                _sendToRecipient(token, m.recipient, amount);
                _emitCrosschainSwapDone(m, amount, 0, DataTypes.SwapStatus.Failed);
            }
        }
    }

    function remoteSwap(
        StargateSwapRequest memory m,
        uint256 amount,
        address token
    )
        external
    {
        if (m.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.OnDestChain || m.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.Both) { // When case using paraswap
            if (amount >= m.bridgeDstAmount) {
                _callParaswap(IERC20(token), m.bridgeDstAmount, m.dstParaswapData);
                _sendToRecipient(token, m.recipient, amount - m.bridgeDstAmount);
                _emitCrosschainSwapDone(m, m.bridgeDstAmount, m.estimatedDstAmount, DataTypes.SwapStatus.Succeeded);
            } else {
                _executeWithDistribution(m, amount);
            }
        } else {
            _executeWithDistribution(m, amount);
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

    function _swapInternalForStargate(
        uint256 amount,
        uint256 parts,
        uint256 lastNonZeroIndex,
        StargateSwapRequest memory m // callData
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

    function _executeWithDistribution(
        StargateSwapRequest memory m,
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

    function _emitCrosschainSwapDone(StargateSwapRequest memory m, uint256 srcAmount, uint256 dstAmount, DataTypes.SwapStatus status) internal {
        switchEvent.emitCrosschainSwapDone(m.id, m.bridge, m.recipient, m.bridgeToken, m.dstToken, srcAmount, dstAmount, status);
    }
}