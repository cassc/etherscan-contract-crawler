// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IMagpieBridge {
    enum BridgeType {
        Wormhole,
        Stargate
    }

    struct BridgeConfig {
        address stargateRouterAddress;
        address tokenBridgeAddress;
        address coreBridgeAddress;
        uint8 consistencyLevel;
        uint8 networkId;
    }

    struct BridgeArgs {
        bytes encodedVmBridge;
        bytes encodedVmCore;
        bytes senderStargateBridgeAddress;
        uint256 nonce;
        uint16 senderStargateChainId;
    }

    struct ValidationInPayload {
        bytes32 fromAssetAddress;
        bytes32 toAssetAddress;
        bytes32 to;
        bytes32 recipientCoreAddress;
        uint256 amountOutMin;
        uint256 layerZeroRecipientChainId;
        uint256 sourcePoolId;
        uint256 destPoolId;
        uint256 swapOutGasFee;
        uint16 recipientBridgeChainId;
        uint8 recipientNetworkId;
    }

    struct ValidationOutPayload {
        address fromAssetAddress;
        address toAssetAddress;
        address to;
        address senderCoreAddress;
        address recipientCoreAddress;
        uint256 amountOutMin;
        uint256 swapOutGasFee;
        uint256 amountIn;
        uint64 tokenSequence;
        uint8 senderIntermediaryDecimals;
        uint8 senderNetworkId;
        uint8 recipientNetworkId;
        BridgeType bridgeType;
    }

    function updateConfig(BridgeConfig calldata _bridgeConfig) external;

    function bridgeIn(
        BridgeType bridgeType,
        ValidationInPayload memory payload,
        uint256 amount,
        address toAssetAddress,
        address refundAddress
    )
        external
        payable
        returns (
            uint256 depositAmount,
            uint64 coreSequence,
            uint64 tokenSequence
        );

    function getPayload(bytes memory encodedVm)
        external
        view
        returns (ValidationOutPayload memory payload, uint64 sequence);

    function bridgeOut(
        ValidationOutPayload memory payload,
        BridgeArgs memory bridgeArgs,
        uint64 tokenSequence,
        address assetAddress
    ) external returns (uint256 amount);

    function updateMagpieCore(address _magpieCoreAddress) external;

    function adjustAssetDecimals(
        address assetAddress,
        uint8 fromDecimals,
        uint256 amountIn
    ) external view returns (uint256 amount);
}