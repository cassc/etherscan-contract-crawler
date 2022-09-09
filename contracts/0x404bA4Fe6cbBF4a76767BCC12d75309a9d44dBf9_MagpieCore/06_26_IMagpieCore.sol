// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "./IMagpieRouter.sol";
import "./IMagpieBridge.sol";

interface IMagpieCore {
    struct Config {
        address weth;
        address pauserAddress;
        address magpieRouterAddress;
        address magpieBridgeAddress;
        address stargateAddress;
        address tokenBridgeAddress;
        address coreBridgeAddress;
        uint8 consistencyLevel;
        uint8 networkId;
    }

    struct SwapInArgs {
        IMagpieRouter.SwapArgs swapArgs;
        IMagpieBridge.ValidationInPayload payload;
        IMagpieBridge.BridgeType bridgeType;
    }

    struct SwapOutArgs {
        IMagpieRouter.SwapArgs swapArgs;
        IMagpieBridge.BridgeArgs bridgeArgs;
    }

    struct WrapSwapConfig {
        bool transferFromSender;
        bool prepareFromAsset;
        bool prepareToAsset;
        bool unwrapToAsset;
        bool swap;
    }

    function updateConfig(Config calldata config) external;

    function swap(IMagpieRouter.SwapArgs calldata args)
        external
        payable
        returns (uint256[] memory amountOuts);

    function swapIn(SwapInArgs calldata swapArgs)
        external
        payable
        returns (
            uint256[] memory amountOuts,
            uint256 depositAmount,
            uint64,
            uint64
        );

    function swapOut(SwapOutArgs calldata args)
        external
        returns (uint256[] memory amountOuts);

    function sgReceive(
        uint16 senderChainId,
        bytes memory magpieBridgeAddress,
        uint256 nonce,
        address assetAddress,
        uint256 amount,
        bytes memory payload
    ) external;

    event ConfigUpdated(Config config, address caller);

    event Swapped(
        IMagpieRouter.SwapArgs swapArgs,
        uint256[] amountOuts,
        address caller
    );

    event SwappedIn(
        SwapInArgs args,
        uint256[] amountOuts,
        uint256 depositAmount,
        uint8 receipientNetworkId,
        uint64 coreSequence,
        uint64 tokenSequence,
        bytes32 senderAddress,
        address caller
    );

    event SwappedOut(
        SwapOutArgs args,
        uint256[] amountOuts,
        uint8 senderNetworkId,
        uint64 coreSequence,
        bytes32 senderAddress,
        address caller
    );

    event GasFeeWithdraw(
        address indexed tokenAddress,
        address indexed owner,
        uint256 indexed amount
    );
}