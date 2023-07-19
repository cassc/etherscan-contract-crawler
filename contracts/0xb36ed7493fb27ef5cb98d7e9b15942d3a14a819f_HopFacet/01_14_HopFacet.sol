pragma solidity 0.8.17;

import "../libraries/LibDiamond.sol";
import "../libraries/LibData.sol";
import "../libraries/LibPlexusUtil.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IHop.sol";
import "../interfaces/IBridge.sol";
import "../Helpers/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract HopFacet is IBridge, ReentrancyGuard {
    using SafeERC20 for IERC20;

    function initHop(HopMapping[] calldata mappings) external {
        require(msg.sender == LibDiamond.contractOwner());
        LibData.HopBridgeData storage s = LibData.hopStorage();

        for (uint256 i; i < mappings.length; i++) {
            s.bridge[mappings[i].tokenAddress] = mappings[i].bridgeAddress;
            s.relayer[mappings[i].tokenAddress] = mappings[i].relayerAddress;
            s.allowedBridge[mappings[i].bridgeAddress] = true;
            s.allowedRelayer[mappings[i].relayerAddress] = true;
        }
    }

    function bridgeToHop(BridgeData memory _bridgeData, HopData calldata _hopData) external payable nonReentrant {
        LibPlexusUtil._isTokenDeposit(_bridgeData.srcToken, _bridgeData.amount);
        _hopStart(_bridgeData, _hopData);
    }

    function swapAndBridgeToHop(SwapData calldata _swap, BridgeData memory _bridgeData, HopData calldata _hopData) external payable nonReentrant {
        _bridgeData.amount = LibPlexusUtil._tokenDepositAndSwap(_swap);
        _hopStart(_bridgeData, _hopData);
    }

    function _hopStart(BridgeData memory _bridgeData, HopData calldata _hopData) internal {
        bool isNotNative = !LibPlexusUtil._isNative(_bridgeData.srcToken);
        address bridge = hopBridge(_bridgeData.srcToken);
        require(hopBridgeAllowed(bridge) && hopRelayerAllowed(hopRelayer(_bridgeData.srcToken)));

        if (isNotNative) {
            if (IERC20(_bridgeData.srcToken).allowance(address(this), bridge) > 0) {
                IERC20(_bridgeData.srcToken).safeApprove(bridge, 0);
            }
            IERC20(_bridgeData.srcToken).safeIncreaseAllowance(bridge, _bridgeData.amount);
        }
        if (block.chainid == 1) {
            IHop(bridge).sendToL2{value: isNotNative ? 0 : _bridgeData.amount}(
                uint256(_bridgeData.dstChainId),
                _bridgeData.recipient,
                _bridgeData.amount,
                getSlippage(_bridgeData.amount, _hopData.slippage),
                _hopData.deadline,
                hopRelayer(_bridgeData.srcToken),
                _hopData.bonderFee
            );
        } else {
            IHop(bridge).swapAndSend{value: isNotNative ? 0 : _bridgeData.amount}(
                uint256(_bridgeData.dstChainId),
                _bridgeData.recipient,
                _bridgeData.amount,
                _hopData.bonderFee,
                getSlippage(_bridgeData.amount, _hopData.slippage),
                _hopData.deadline,
                _hopData.dstAmountOutMin,
                _hopData.dstDeadline
            );
        }

        emit LibData.Bridge(_bridgeData.recipient, _bridgeData.dstChainId, _bridgeData.srcToken, _bridgeData.amount, _bridgeData.plexusData);
    }

    function hopBridge(address token) private view returns (address) {
        LibData.HopBridgeData storage s = LibData.hopStorage();
        address bridge = s.bridge[token];
        if (bridge == address(0)) revert();
        return bridge;
    }

    function hopRelayer(address token) private view returns (address) {
        LibData.HopBridgeData storage s = LibData.hopStorage();
        address relayer = s.relayer[token];
        if (relayer == address(0)) revert();
        return relayer;
    }

    function hopRelayerAllowed(address relayer) private view returns (bool) {
        LibData.HopBridgeData storage s = LibData.hopStorage();
        bool allowed = s.allowedRelayer[relayer];
        return allowed;
    }

    function hopBridgeAllowed(address bridge) private view returns (bool) {
        LibData.HopBridgeData storage s = LibData.hopStorage();
        bool allowed = s.allowedBridge[bridge];
        return allowed;
    }

    // percent
    function getSlippage(uint256 amount, uint256 percent) private view returns (uint256) {
        uint256 amountOutMin = amount - ((amount * percent) / 1000);
    }
}