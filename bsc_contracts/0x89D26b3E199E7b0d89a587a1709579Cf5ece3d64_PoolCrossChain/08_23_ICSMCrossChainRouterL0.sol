// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ICSMCrossChainRouterL0 {
    struct CrossChainAsset {
        uint256 cash;
        uint256 liability;
        uint16 decimals;
        uint64 assetId;
        address nativeAssetAddress; // address of the IAsset on the native chain
        address nativeTokenAddress; // address of the underlying token on the native chain
    }

    struct CrossChainParams {
        CrossChainAsset fromAsset;
        CrossChainAsset toAsset;
        uint256 estimatedFee;
        bytes payload;
    }

    struct CCReceiveParams {
        address sender;
        uint16 srcChainId;
        uint16 dstChainId;
        address srcAsset;
        address dstAsset;
        uint256 amount;
        uint256 haircut;
        bytes signature;
    }

    function isApprovedAsset(uint16 chainId_, uint256 assetId_) external view returns (bool);

    function isApprovedAsset(uint16 chainId_, address assetAddress_) external view returns (bool);

    function getAssetData(uint16 chainId_, uint256 assetId_) external view returns (CrossChainAsset memory);

    function getAssetData(uint16 chainId_, address assetAddress_) external view returns (CrossChainAsset memory);

    function getApprovedAssetId(address assetAddress_, uint16 chainId_) external view returns (uint256);

    function getCrossChainAssetParams(uint16 chainId_, uint256 assetId_) external view returns (uint256, uint256);

    function estimateFee(uint16 dstChain_, bytes calldata payload_) external view returns (uint256);

    function route(
        uint16 dstChain_,
        address dstAddress_,
        uint256 fee_,
        bytes calldata payload_
    ) external payable;

    function lzReceive(
        uint16 srcChainId_,
        bytes memory srcAddressBytes_,
        uint64 nonce_,
        bytes memory payload_
    ) external;

    function modifyCrossChainParams(
        uint16 chainId_,
        uint256 assetId_,
        uint256 cash_,
        uint256 liability_
    ) external;

    function toggleAssetAndChain(
        uint16 chainId_,
        address assetAddress_,
        address tokenAddress_,
        uint256 assetId_,
        uint16 decimals_,
        bool add_
    ) external;

    function nextNonce(uint16 dstChain_) external view returns (uint256);
}