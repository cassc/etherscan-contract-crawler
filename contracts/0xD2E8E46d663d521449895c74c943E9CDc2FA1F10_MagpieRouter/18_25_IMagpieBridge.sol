// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IMagpieBridge {
    enum BridgeType {
        Wormhole,
        Hyphen
    }

    enum DepositHashStatus {
        Pending,
        Approved,
        Successful
    }

    struct BridgeConfig {
        address hyphenLiquidityPoolAddress;
        address tokenBridgeAddress;
        address coreBridgeAddress;
        address relayerAddress;
        uint256 hyphenBaseDivisor;
        uint8 consistencyLevel;
        uint8 networkId;
    }

    struct ValidationInPayload {
        bytes32 fromAssetAddress;
        bytes32 toAssetAddress;
        bytes32 to;
        uint256 amountOutMin;
        bytes32 recipientCoreAddress;
        uint256 recipientChainId;
        uint16 recipientBridgeChainId;
        uint256 swapOutGasFee;
        uint256 destGasTokenAmount;
        uint256 destGasTokenAmountOutMin;
        uint8 recipientNetworkId;
    }

    struct ValidationOutPayload {
        address fromAssetAddress;
        address toAssetAddress;
        address to;
        address recipientCoreAddress;
        uint256 amountOutMin;
        uint256 swapOutGasFee;
        uint256 destGasTokenAmount;
        uint256 destGasTokenAmountOutMin;
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
        address toAssetAddress
    )
        external
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
        uint64 coreSequence,
        uint64 tokenSequence,
        address assetAddress,
        bytes memory encodedVmBridge,
        bytes memory depositHash,
        address caller
    ) external returns (uint256 amount);

    function updateMagpieCore(address _magpieCoreAddress) external;

    function adjustAssetDecimals(
        address assetAddress,
        uint8 fromDecimals,
        uint256 amountIn
    ) external view returns (uint256 amount);
}