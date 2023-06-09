// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import "../../library/Uniswap/Uniswap.sol";

interface IPricing {

    event EvaluateAsset(address indexed asset, address indexed sender);
    event UnevaluateAsset(address indexed asset, address indexed sender);
    event PathUpdate(
        address indexed path,
        address[] prevFromPath,
        address[] newFromPath,
        address[] prevToPath,
        address[] newToPath,
        address indexed sender
    );

    struct Prices {
        uint32 timestamp;
        uint112 floorPrice;
        uint112 currentPrice;
    }

    struct AssetDetails {
        uint32 timestamp;

        address primaryAsset;

        // TOTALS
        uint128 tokensTotal;
        uint128 backingTotal;

        uint128 tokensCirculating;
        uint128 tokensReserves;

        uint128 backingReserves;
        uint128 backingTreasury;
        uint128 backingDebt;
    }

    function ROUTER() external view returns (address);
    function FACTORY() external view returns (address);
    function BASE_ASSET() external view returns (address);
    function USDC_ADDRESS() external view returns (address);

    function evaluated(address asset) external view returns (bool);
    function evaluatedAssetAt(uint256 index) external view returns (address);
    function evaluatedAssets() external view returns (address[] memory);
    function totalEvaluatedAssets() external view returns (uint256);

    function pathFromBase(address asset) external view returns (address[] memory);
    function pathToBase(address asset) external view returns (address[] memory);

    function assetToBase(address asset, uint256 assetAmount) external view returns (uint256);
    function assetFromBase(address asset, uint256 assetAmount) external view returns (uint256);
    function baseToAsset(address asset, uint256 baseAmount) external view returns (uint256);
    function baseFromAsset(address asset, uint256 baseAmount) external view returns (uint256);
    function assetToAsset(address toAsset, address fromAsset, uint256 fromAmount) external view returns (uint256);
    function assetFromAsset(address toAsset, address fromAsset, uint256 toAmount) external view returns (uint256);
    function assetToUSD(address asset, uint256 assetAmount) external view returns (uint256);
    function usdFromAsset(address asset, uint256 assetAmount) external view returns (uint256);
    function assetToTokens(address asset, uint256 price, uint256 assetAmount) external view returns (uint256);
    function tokensFromAsset(address asset, uint256 price, uint256 assetAmount) external view returns (uint256);
    function tokensToAsset(address asset, uint256 price, uint256 tokenAmount) external view returns (uint256);
    function assetFromTokens(address asset, uint256 price, uint256 tokenAmount) external view returns (uint256);

    function updatePaths(address _asset, address[] memory _pathFromBase, address[] memory _pathToBase) external;
    function evaluateAsset(address _asset) external;
    function unevaluateAsset(address _asset) external;

    function constructPath(address from, address to) external view returns (address[] memory path);

    function evaluate() external view returns (Prices memory prices, AssetDetails memory assets);

    function calculateAssets() external view returns (AssetDetails memory assetDetails);
    function calculateFloorPrice(AssetDetails memory assetDetails) external pure returns (uint112);
    function calculatePrices(AssetDetails memory assetDetails) external view returns (Prices memory prices);
    function evaluateReserves() external view returns (uint128 totalBackingReserves, uint128 totalTokenReserves);
    function evaluateAssets() external view returns (uint128 treasuryEvaluation, uint128 debtEvaluation, address _primaryAsset);
}