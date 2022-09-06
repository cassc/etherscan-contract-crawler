// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.4;
pragma abicoder v2;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IUniswapV3MintCallback} from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {PositionKey} from "@uniswap/v3-periphery/contracts/libraries/PositionKey.sol";

import {Faucet} from "../libraries/Faucet.sol";
import {IVaultTreasury} from "../interfaces/IVaultTreasury.sol";
import {IVaultStorage} from "../interfaces/IVaultStorage.sol";

import {IUniswapMath} from "../libraries/uniswap/IUniswapMath.sol";
import {SharedEvents} from "../libraries/SharedEvents.sol";
import {Constants} from "../libraries/Constants.sol";

import "hardhat/console.sol";

contract VaultTreasury is IVaultTreasury, ReentrancyGuard, IUniswapV3MintCallback, Faucet {
    using SafeERC20 for IERC20;

    constructor() Faucet() {}

    /// @dev wrapper around getAmountsForLiquidity
    function amountsForLiquidity(
        address pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) public view override onlyContracts returns (uint256, uint256) {
        (uint160 sqrtRatioX96, , , , , , ) = IUniswapV3Pool(pool).slot0();
        return
            IUniswapMath(uniswapMath).getAmountsForLiquidity(
                sqrtRatioX96,
                IUniswapMath(uniswapMath).getSqrtRatioAtTick(tickLower),
                IUniswapMath(uniswapMath).getSqrtRatioAtTick(tickUpper),
                liquidity
            );
    }

    /// @dev Wrapper around `IUniswapV3Pool.positions()`.
    function position(
        address pool,
        int24 tickLower,
        int24 tickUpper
    )
        public
        view
        override
        onlyContracts
        returns (
            uint128,
            uint256,
            uint256,
            uint128,
            uint128
        )
    {
        bytes32 positionKey = PositionKey.compute(address(this), tickLower, tickUpper);
        return IUniswapV3Pool(pool).positions(positionKey);
    }

    /// @dev return amount of tokens in both pools
    function allAmountsForLiquidity(
        Constants.Boundaries memory boundaries,
        uint128 liquidityEthUsdc,
        uint128 liquidityOsqthEth
    )
        external
        view
        override
        onlyContracts
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 usdcAmount, uint256 ethAmount0) = amountsForLiquidity(
            Constants.poolEthUsdc,
            boundaries.ethUsdcLower,
            boundaries.ethUsdcUpper,
            liquidityEthUsdc
        );
        (uint256 ethAmount1, uint256 osqthAmount) = amountsForLiquidity(
            Constants.poolEthOsqth,
            boundaries.osqthEthLower,
            boundaries.osqthEthUpper,
            liquidityOsqthEth
        );

        return (ethAmount0 + ethAmount1, usdcAmount, osqthAmount);
    }

    /// @dev wrapper around "IUniswapV3Pool(pool).burn"
    function burn(
        address pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) public override onlyContracts returns (uint256, uint256) {
        return IUniswapV3Pool(pool).burn(tickLower, tickUpper, liquidity);
    }

    /// @dev wrapper around "IUniswapV3Pool(pool).collect"
    function collect(
        address pool,
        int24 tickLower,
        int24 tickUpper
    ) external override onlyContracts returns (uint256 collect0, uint256 collect1) {
        address recipient = address(this);

        (collect0, collect1) = IUniswapV3Pool(pool).collect(
            recipient,
            tickLower,
            tickUpper,
            type(uint128).max,
            type(uint128).max
        );
    }

    /// @dev wrapper around "IUniswapV3Pool(pool).mint"
    function mintLiquidity(
        address pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external override onlyContracts {
        if (liquidity > 0) {
            address token0 = pool == Constants.poolEthUsdc ? address(Constants.usdc) : address(Constants.weth);
            address token1 = pool == Constants.poolEthUsdc ? address(Constants.weth) : address(Constants.osqth);
            bytes memory params = abi.encode(pool, token0, token1);

            IUniswapV3Pool(pool).mint(address(this), tickLower, tickUpper, liquidity, params);
        }
    }

    /// @dev ERC20 transfer
    function transfer(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external override onlyContracts {
        token.transfer(recipient, amount);
    }

    /// @dev Callback for Uniswap V3 pool.
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external override {
        (address pool, address token0, address token1) = abi.decode(data, (address, address, address));

        require(msg.sender == pool, "C20");
        if (amount0Owed > 0) IERC20(token0).safeTransfer(msg.sender, amount0Owed);
        if (amount1Owed > 0) IERC20(token1).safeTransfer(msg.sender, amount1Owed);
    }

    /**
     * @dev Do zero-burns to poke a position on Uniswap so earned fees are
     * updated. Should be called if total amounts needs to include up-to-date
     * fees.
     * @param pool address of pool to poke
     * @param tickLower lower tick of the position
     * @param tickUpper upper tick of the position
     */
    function poke(
        address pool,
        int24 tickLower,
        int24 tickUpper
    ) internal {
        (uint128 liquidity, , , , ) = position(pool, tickLower, tickUpper);

        if (liquidity > 0) {
            burn(pool, tickLower, tickUpper, 0);
        }
    }

    /// @dev poke for ETH-USDC pool
    function pokeEthUsdc() external override onlyVault {
        poke(
            address(Constants.poolEthUsdc),
            IVaultStorage(vaultStorage).orderEthUsdcLower(),
            IVaultStorage(vaultStorage).orderEthUsdcUpper()
        );
    }

    /// @dev poke for ETH-oSQTH pool
    function pokeEthOsqth() external override onlyVault {
        poke(
            address(Constants.poolEthOsqth),
            IVaultStorage(vaultStorage).orderOsqthEthLower(),
            IVaultStorage(vaultStorage).orderOsqthEthUpper()
        );
    }

    /// @dev liquidity of the position in the ETH-USDC pool
    function positionLiquidityEthUsdc() external view override onlyVault returns (uint128) {
        (uint128 liquidityEthUsdc, , , , ) = position(
            Constants.poolEthUsdc,
            IVaultStorage(vaultStorage).orderEthUsdcLower(),
            IVaultStorage(vaultStorage).orderEthUsdcUpper()
        );

        return liquidityEthUsdc;
    }

    /// @dev liquidity of the position in the ETH-oSQTH pool
    function positionLiquidityEthOsqth() external view override onlyVault returns (uint128) {
        (uint128 liquidityEthOsqth, , , , ) = position(
            Constants.poolEthOsqth,
            IVaultStorage(vaultStorage).orderOsqthEthLower(),
            IVaultStorage(vaultStorage).orderOsqthEthUpper()
        );

        return liquidityEthOsqth;
    }
}