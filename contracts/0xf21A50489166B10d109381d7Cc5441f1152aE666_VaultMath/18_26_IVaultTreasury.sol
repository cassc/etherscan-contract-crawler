// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.4;
pragma abicoder v2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Constants} from "../libraries/Constants.sol";

interface IVaultTreasury {
    function burn(
        address pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external returns (uint256, uint256);

    function collect(
        address pool,
        int24 tickLower,
        int24 tickUpper
    ) external returns (uint256 collect0, uint256 collect1);

    function mintLiquidity(
        address pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external;

    function transfer(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;

    function amountsForLiquidity(
        address pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external view returns (uint256, uint256);

    function allAmountsForLiquidity(
        Constants.Boundaries memory boundaries,
        uint128 liquidityEthUsdc,
        uint128 liquidityOsqthEth
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function position(
        address pool,
        int24 tickLower,
        int24 tickUpper
    )
        external
        view
        returns (
            uint128,
            uint256,
            uint256,
            uint128,
            uint128
        );

    function positionLiquidityEthUsdc() external view returns (uint128);

    function positionLiquidityEthOsqth() external view returns (uint128);

    function pokePools() external;

    function externalPoke() external;
}