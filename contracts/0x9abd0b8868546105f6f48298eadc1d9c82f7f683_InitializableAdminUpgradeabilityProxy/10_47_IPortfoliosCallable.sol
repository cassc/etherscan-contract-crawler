pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "../utils/Common.sol";

interface IPortfoliosCallable {
    function getAssets(address account) external view returns (Common.Asset[] memory);

    function getCashGroup(uint8 cashGroupId) external view returns (Common.CashGroup memory);

    function getCashGroups(uint8[] calldata groupIds) external view returns (Common.CashGroup[] memory);

    function settleMaturedAssets(address account) external;

    function settleMaturedAssetsBatch(address[] calldata account) external;

    function upsertAccountAsset(address account, Common.Asset calldata assets, bool checkFreeCollateral) external;

    function upsertAccountAssetBatch(address account, Common.Asset[] calldata assets, bool checkFreeCollateral) external;

    function mintfCashPair(address payer, address receiver, uint8 cashGroupId, uint32 maturity, uint128 notional) external;

    function freeCollateral(address account) external returns (int256, int256[] memory, int256[] memory);

    function freeCollateralView(address account) external view returns (int256, int256[] memory, int256[] memory);

    function freeCollateralAggregateOnly(address account) external returns (int256);

    function freeCollateralFactors(
        address account,
        uint256 localCurrency,
        uint256 collateralCurrency
    ) external returns (Common.FreeCollateralFactors memory);

    function setNumCurrencies(uint16 numCurrencies) external;

    function transferAccountAsset(
        address from,
        address to,
        bytes1 assetType,
        uint8 cashGroupId,
        uint16 instrumentId,
        uint32 maturity,
        uint128 value
    ) external;

    function searchAccountAsset(
        address account,
        bytes1 assetType,
        uint8 cashGroupId,
        uint16 instrumentId,
        uint32 maturity
    ) external view returns (Common.Asset memory, uint256);

    function raiseCurrentCashViaLiquidityToken(
        address account,
        uint16 currency,
        uint128 amount
    ) external returns (uint128);

    function raiseCurrentCashViaCashReceiver(
        address account,
        address liquidator,
        uint16 currency,
        uint128 amount
    ) external returns (uint128, uint128);
}