// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.4;
pragma abicoder v2;

import "../libraries/Constants.sol";

interface IVaultMath {
    function isTimeRebalance() external view returns (bool, uint256);

    function isPriceRebalance(uint256 _auctionTriggerTime) external view returns (bool);

    function burnAndCollect(
        address pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    )
        external
        returns (
            uint256 burned0,
            uint256 burned1,
            uint256 feesToVault0,
            uint256 feesToVault1
        );

    function burnLiquidityShare(
        address pool,
        int24 tickLower,
        int24 tickUpper,
        uint256 shares,
        uint256 totalSupply
    ) external returns (uint256 amount0, uint256 amount1);

    function getTotalAmounts()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getPrices() external view returns (uint256 ethUsdcPrice, uint256 osqthEthPrice);

    function getIV() external view returns (uint256);

    function getValue(
        uint256 amountEth,
        uint256 amountUsdc,
        uint256 amountOsqth,
        uint256 ethUsdcPrice,
        uint256 osqthEthPrice
    ) external pure returns (uint256);

    function getPriceMultiplier(uint256 _auctionTriggerTime, bool _isPosIVbump) external view returns (uint256);

    function getLiquidityForValue(
        uint256 v,
        uint256 p,
        uint256 pL,
        uint256 pH,
        uint256 digits
    ) external pure returns (uint128);

    function getValueForLiquidity(
        uint128 lEthUsdc,
        uint256 aP,
        uint256 pL,
        uint256 pH,
        uint256 digits
    ) external pure returns (uint256);

    function getPriceFromTick(int24 tick) external view returns (uint256);
}