// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IBridge.sol";
import "../interfaces/IXybridge.sol";
import "../Helpers/ReentrancyGuard.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/LibData.sol";
import "../libraries/LibPlexusUtil.sol";
import "hardhat/console.sol";

contract XyBridgeFacet is IBridge, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IXybridge private immutable xybridge;

    constructor(IXybridge _xybridge) {
        xybridge = _xybridge;
    }

    function bridgeToXybridge(BridgeData memory _bridgeData, XyBridgeData memory _xyDesc) external payable nonReentrant {
        LibPlexusUtil._isTokenDeposit(_bridgeData.srcToken, _bridgeData.amount);
        _xybridgeStart(_bridgeData, _xyDesc);
    }

    function swapAndBridgeToXybridge(
        SwapData calldata _swap,
        BridgeData memory _bridgeData,
        XyBridgeData memory _xyDesc
    ) external payable nonReentrant {
        _bridgeData.amount = LibPlexusUtil._tokenDepositAndSwap(_swap);
        _xybridgeStart(_bridgeData, _xyDesc);
    }

    function _xybridgeStart(BridgeData memory _bridgeData, XyBridgeData memory _xyDesc) internal {
        bool isNotNative = !LibPlexusUtil._isNative(_bridgeData.srcToken);
        if (isNotNative) {
            IERC20(_bridgeData.srcToken).safeApprove(address(xybridge), _bridgeData.amount);
            SwapDescription memory swapDesc = SwapDescription({
                fromToken: IERC20(_bridgeData.srcToken),
                toToken: IERC20(_bridgeData.srcToken),
                receiver: _bridgeData.recipient,
                amount: _bridgeData.amount,
                minReturnAmount: _bridgeData.amount
            });
            ToChainDescription memory tcDesc = ToChainDescription({
                toChainId: uint32(_bridgeData.dstChainId),
                toChainToken: IERC20(_xyDesc.toChainToken),
                expectedToChainTokenAmount: _bridgeData.amount,
                slippage: 0
            });
            xybridge.swapWithReferrer(_xyDesc.aggregatorAdaptor, swapDesc, "0x", tcDesc, _xyDesc.referrer);
            IERC20(_bridgeData.srcToken).safeApprove(address(xybridge), 0);
        } else {
            SwapDescription memory swapDesc = SwapDescription({
                fromToken: IERC20(_bridgeData.srcToken),
                toToken: IERC20(_bridgeData.srcToken),
                receiver: _bridgeData.recipient,
                amount: _bridgeData.amount,
                minReturnAmount: _bridgeData.amount
            });
            ToChainDescription memory tcDesc = ToChainDescription({
                toChainId: uint32(_bridgeData.dstChainId),
                toChainToken: IERC20(_xyDesc.toChainToken),
                expectedToChainTokenAmount: _bridgeData.amount,
                slippage: 0
            });
            xybridge.swapWithReferrer{value: msg.value}(_xyDesc.aggregatorAdaptor, swapDesc, "0x", tcDesc, _xyDesc.referrer);
        }
        emit LibData.Bridge(msg.sender, _bridgeData.dstChainId, _bridgeData.srcToken, _bridgeData.amount, _bridgeData.plexusData);
    }
}