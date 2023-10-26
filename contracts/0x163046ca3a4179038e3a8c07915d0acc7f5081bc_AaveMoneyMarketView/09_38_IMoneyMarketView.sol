//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC20Metadata as IERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../libraries/DataTypes.sol";

struct Balances {
    uint256 collateral;
    uint256 debt;
}

struct NormalisedBalances {
    uint256 collateral;
    uint256 debt;
    uint256 unit;
}

struct Prices {
    uint256 collateral;
    uint256 debt;
    uint256 unit;
}

interface IMoneyMarketView {

    function moneyMarketId() external view returns (MoneyMarketId);

    function balances(PositionId positionId, IERC20 collateralAsset, IERC20 debtAsset) external returns (Balances memory balances_);

    function normalisedBalances(PositionId positionId, IERC20 collateralAsset, IERC20 debtAsset)
        external
        returns (NormalisedBalances memory balances);

    function prices(Symbol symbol, IERC20 collateralAsset, IERC20 debtAsset) external view returns (Prices memory prices_);

    function borrowingLiquidity(IERC20 asset) external view returns (uint256);

    function lendingLiquidity(IERC20 asset) external view returns (uint256);

    function minCR(PositionId positionId, IERC20 collateralAsset, IERC20 debtAsset) external view returns (uint256);

    function thresholds(PositionId positionId, IERC20 collateralAsset, IERC20 debtAsset)
        external
        view
        returns (uint256 ltv, uint256 liquidationThreshold);

    function borrowingRate(IERC20 asset) external view returns (uint256 borrowingRate_);

    function lendingRate(IERC20 asset) external view returns (uint256 lendingRate_);

}