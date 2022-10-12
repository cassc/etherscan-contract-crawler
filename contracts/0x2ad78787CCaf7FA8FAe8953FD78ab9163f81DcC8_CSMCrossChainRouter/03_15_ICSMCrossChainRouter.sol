// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ICSMCrossChainRouter {
    struct CrossChainAsset {
        uint256 cash;
        uint256 liability;
        uint256 decimals;
        uint64 assetId;
        address nativeAssetAddress; // address of the IAsset on the native chain
        address nativeTokenAddress; // address of the underlying token on the native chain
    }

    struct CrossChainParams {
        CrossChainAsset fromAsset;
        CrossChainAsset toAsset;
        uint256 actualToAmount;
        uint256 haircut;
        bytes payload;
        uint256 nonce;
    }

    function isApprovedAsset(uint256 chainId_, uint256 assetId_) external view returns (bool);

    function isApprovedAsset(uint256 chainId_, address assetAddress_) external view returns (bool);

    function isApprovedRouter(uint256 chainId_, address router_) external view returns (bool);

    function getAssetData(uint256 chainId_, uint256 assetId_) external view returns (CrossChainAsset memory);

    function getAssetData(uint256 chainId_, address assetAddress_) external view returns (CrossChainAsset memory);

    function getApprovedAssetId(address assetAddress_, uint256 chainId_) external view returns (uint256);

    function getCrossChainAssetParams(uint256 chainId_, uint256 assetId_) external view returns (uint256, uint256);

    function estimateFee() external view returns (uint256);

    function route(
        uint256 dstChain_,
        address dstAddress_,
        bytes calldata payload_,
        uint256 executionFee_
    ) external payable;

    function routerReceive(
        address sender_,
        address srcAsset_,
        address dstAsset_,
        uint256 amount_,
        uint256 haircut_,
        uint256 nonce_
    ) external;

    function modifyCrossChainParams(
        uint256 chainId_,
        uint256 assetId_,
        uint256 cash_,
        uint256 liability_
    ) external;

    function toggleAssetAndChain(
        uint256 chainId_,
        address assetAddress_,
        address tokenAddress_,
        uint256 assetId_,
        uint256 decimals_,
        bool add_
    ) external;
}