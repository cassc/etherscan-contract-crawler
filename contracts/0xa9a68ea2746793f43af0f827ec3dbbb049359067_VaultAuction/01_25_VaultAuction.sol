// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.4;
pragma abicoder v2;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IVaultTreasury} from "../interfaces/IVaultTreasury.sol";
import {IVaultMath} from "../interfaces/IVaultMath.sol";
import {IAuction} from "../interfaces/IAuction.sol";
import {IVaultStorage} from "../interfaces/IVaultStorage.sol";

import {SharedEvents} from "../libraries/SharedEvents.sol";
import {PRBMathUD60x18} from "../libraries/math/PRBMathUD60x18.sol";
import {Constants} from "../libraries/Constants.sol";
import {Faucet} from "../libraries/Faucet.sol";
import {IUniswapMath} from "../libraries/uniswap/IUniswapMath.sol";

import "hardhat/console.sol";

contract VaultAuction is IAuction, Faucet, ReentrancyGuard {
    using PRBMathUD60x18 for uint256;

    /**
     * @notice strategy constructor
     */
    constructor() Faucet() {}

    /**
     * @notice strategy rebalancing based on time threshold
     * @param keeper keeper address
     * @param minAmountEth min amount of wETH to receive
     * @param minAmountUsdc min amount of USDC to receive
     * @param minAmountOsqth miin amount of oSQTH to receive
     */
    function timeRebalance(
        address keeper,
        uint256 minAmountEth,
        uint256 minAmountUsdc,
        uint256 minAmountOsqth
    ) external override nonReentrant notPaused {
        //check if rebalancing based on time threshold is allowed
        (bool isTimeRebalanceAllowed, uint256 auctionTriggerTime) = IVaultMath(vaultMath).isTimeRebalance();

        require(isTimeRebalanceAllowed, "C10");

        _executeAuction(
            keeper,
            auctionTriggerTime,
            Constants.AuctionMinAmounts(minAmountEth, minAmountUsdc, minAmountOsqth)
        );

        emit SharedEvents.TimeRebalance(keeper, auctionTriggerTime, minAmountEth, minAmountUsdc, minAmountOsqth);
    }

    /**
     * @notice strategy rebalancing based on price threshold
     * @param keeper keeper address
     * @param auctionTriggerTime the time when the price deviation threshold was exceeded and when the auction started
     * @param minAmountEth min amount of wETH to receive
     * @param minAmountUsdc min amount of USDC to receive
     * @param minAmountOsqth miin amount of oSQTH to receive
     */
    function priceRebalance(
        address keeper,
        uint256 auctionTriggerTime,
        uint256 minAmountEth,
        uint256 minAmountUsdc,
        uint256 minAmountOsqth
    ) external override nonReentrant notPaused {
        //check if rebalancing based on price threshold is allowed
        require(IVaultMath(vaultMath).isPriceRebalance(auctionTriggerTime), "C11");

        _executeAuction(
            keeper,
            auctionTriggerTime,
            Constants.AuctionMinAmounts(minAmountEth, minAmountUsdc, minAmountOsqth)
        );

        emit SharedEvents.PriceRebalance(keeper, minAmountEth, minAmountUsdc, minAmountOsqth);
    }

    /**
     * @notice execute auction based on the parameters calculated
     * @dev withdraw all liquidity from the positions
     * @dev pull in tokens from keeper
     * @dev sell excess tokens to sender
     * @dev place new positions in ETH-USDC pool and oSQTH-ETH pool
     */
    function _executeAuction(
        address _keeper,
        uint256 _auctionTriggerTime,
        Constants.AuctionMinAmounts memory minAmounts
    ) internal {
        //Calculate auction params
        Constants.AuctionParams memory params = _getAuctionParams(_auctionTriggerTime);

        //Withdraw all the liqudity from the positions
        IVaultMath(vaultMath).burnAndCollect(
            Constants.poolEthUsdc,
            IVaultStorage(vaultStorage).orderEthUsdcLower(),
            IVaultStorage(vaultStorage).orderEthUsdcUpper(),
            IVaultTreasury(vaultTreasury).positionLiquidityEthUsdc()
        );

        IVaultMath(vaultMath).burnAndCollect(
            Constants.poolEthOsqth,
            IVaultStorage(vaultStorage).orderOsqthEthLower(),
            IVaultStorage(vaultStorage).orderOsqthEthUpper(),
            IVaultTreasury(vaultTreasury).positionLiquidityEthOsqth()
        );

        {
            //Calculate amounts that need to be exchanged with keeper
            (uint256 ethBalance, uint256 usdcBalance, uint256 osqthBalance) = IVaultMath(vaultMath).getTotalAmounts();

            (uint256 targetEth, uint256 targetUsdc, uint256 targetOsqth) = _getTargets(
                params.boundaries,
                params.liquidityEthUsdc,
                params.liquidityOsqthEth
            );

            //Exchange tokens with keeper
            _swapWithKeeper(ethBalance, targetEth, minAmounts.minAmountEth, address(Constants.weth), _keeper);
            _swapWithKeeper(usdcBalance, targetUsdc, minAmounts.minAmountUsdc, address(Constants.usdc), _keeper);
            _swapWithKeeper(osqthBalance, targetOsqth, minAmounts.minAmountOsqth, address(Constants.osqth), _keeper);
        }

        //Place new positions
        IVaultTreasury(vaultTreasury).mintLiquidity(
            Constants.poolEthUsdc,
            params.boundaries.ethUsdcLower,
            params.boundaries.ethUsdcUpper,
            params.liquidityEthUsdc
        );

        IVaultTreasury(vaultTreasury).mintLiquidity(
            Constants.poolEthOsqth,
            params.boundaries.osqthEthLower,
            params.boundaries.osqthEthUpper,
            params.liquidityOsqthEth
        );

        IVaultStorage(vaultStorage).setSnapshot(
            params.boundaries.ethUsdcLower,
            params.boundaries.ethUsdcUpper,
            params.boundaries.osqthEthLower,
            params.boundaries.osqthEthUpper,
            block.timestamp,
            IVaultMath(vaultMath).getIV(),
            params.totalValue,
            params.ethUsdcPrice
        );
    }

    /**
     * @notice calculate all auction parameters
     * @param _auctionTriggerTime timestamp when auction started
     */
    function _getAuctionParams(uint256 _auctionTriggerTime) internal view returns (Constants.AuctionParams memory) {
        //current ETH/USDC and oSQTH/ETH price
        (uint256 ethUsdcPrice, uint256 osqthEthPrice) = IVaultMath(vaultMath).getPrices();

        uint256 valueMultiplier;
        uint256 priceMultiplier;
        Constants.Boundaries memory boundaries;
        {
            //scope to avoid stack too deep error
            //current implied volatility
            uint256 cIV = IVaultMath(vaultMath).getIV();

            //previous implied volatility
            uint256 pIV = IVaultStorage(vaultStorage).ivAtLastRebalance();

            //is positive IV bump
            bool isPosIVbump = cIV < pIV;

            priceMultiplier = IVaultMath(vaultMath).getPriceMultiplier(_auctionTriggerTime, isPosIVbump);

            //expected IV bump
            uint256 expIVbump;
            if (isPosIVbump) {
                expIVbump = pIV.div(cIV);
                valueMultiplier = priceMultiplier.div(priceMultiplier + uint256(1e18)) + uint256(1e16).div(cIV);
            } else {
                expIVbump = cIV.div(pIV);
                valueMultiplier = priceMultiplier.div(priceMultiplier + uint256(1e18)) - uint256(1e16).div(cIV);
            }
            //IV bump > 2.5 leads to a negative values of one of the lower or upper boundary
            expIVbump = expIVbump > uint256(25e17) ? uint256(25e17) : expIVbump;

            //boundaries for auction prices (current price * multiplier)
            boundaries = _getBoundaries(
                ethUsdcPrice.mul(priceMultiplier),
                osqthEthPrice.mul(priceMultiplier),
                isPosIVbump,
                expIVbump
            );
        }

        //total ETH value of the strategy holdings at the current prices
        uint256 totalValue;
        {
            //scope to avoid stack too deep error

            //current balances
            (uint256 ethBalance, uint256 usdcBalance, uint256 osqthBalance) = IVaultMath(vaultMath).getTotalAmounts();

            totalValue = IVaultMath(vaultMath).getValue(
                ethBalance,
                usdcBalance,
                osqthBalance,
                ethUsdcPrice,
                osqthEthPrice
            );
        }

        //Calculate liquidities
        uint128 liquidityEthUsdc;
        uint128 liquidityOsqthEth;
        {
            //scope to avoid stack too deep error
            liquidityEthUsdc = IVaultMath(vaultMath).getLiquidityForValue(
                totalValue.mul(ethUsdcPrice).mul(valueMultiplier),
                ethUsdcPrice,
                uint256(1e30).div(IVaultMath(vaultMath).getPriceFromTick(boundaries.ethUsdcLower)),
                uint256(1e30).div(IVaultMath(vaultMath).getPriceFromTick(boundaries.ethUsdcUpper)),
                1e12
            );

            liquidityOsqthEth = IVaultMath(vaultMath).getLiquidityForValue(
                totalValue.mul(uint256(1e18) - valueMultiplier),
                osqthEthPrice,
                uint256(1e18).div(IVaultMath(vaultMath).getPriceFromTick(boundaries.osqthEthLower)),
                uint256(1e18).div(IVaultMath(vaultMath).getPriceFromTick(boundaries.osqthEthUpper)),
                1e18
            );

            //Strategy values at the auction prices
            uint256 value0 = IVaultMath(vaultMath).getValueForLiquidity(
                liquidityEthUsdc,
                ethUsdcPrice.mul(priceMultiplier),
                uint256(1e30).div(IVaultMath(vaultMath).getPriceFromTick(boundaries.ethUsdcLower)),
                uint256(1e30).div(IVaultMath(vaultMath).getPriceFromTick(boundaries.ethUsdcUpper)),
                1e12
            );

            uint256 value1 = IVaultMath(vaultMath).getValueForLiquidity(
                liquidityOsqthEth,
                osqthEthPrice.mul(priceMultiplier),
                uint256(1e18).div(IVaultMath(vaultMath).getPriceFromTick(boundaries.osqthEthLower)),
                uint256(1e18).div(IVaultMath(vaultMath).getPriceFromTick(boundaries.osqthEthUpper)),
                1e18
            );
            //Coefficient for auction adjustment
            uint256 k = (totalValue).div(value0 + value1);
            liquidityEthUsdc = uint128(k.mul(uint256(liquidityEthUsdc)));
            liquidityOsqthEth = uint128(k.mul(uint256(liquidityOsqthEth)));
        }

        return Constants.AuctionParams(boundaries, liquidityEthUsdc, liquidityOsqthEth, totalValue, ethUsdcPrice);
    }

    /**
     * @notice calculate amounts that will be exchanged during auction
     * @param boundaries positions boundaries
     * @param liquidityEthUsdc target liquidity for ETH:USDC pool
     * @param liquidityOsqthEth target liquidity for oSQTH:ETH pool
     */
    function _getTargets(
        Constants.Boundaries memory boundaries,
        uint128 liquidityEthUsdc,
        uint128 liquidityOsqthEth
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 ethAmount, uint256 usdcAmount, uint256 osqthAmount) = IVaultTreasury(vaultTreasury)
            .allAmountsForLiquidity(boundaries, liquidityEthUsdc, liquidityOsqthEth);

        return (ethAmount, usdcAmount, osqthAmount);
    }

    /**
     * @notice calculate lp-positions boundaries
     * @param aEthUsdcPrice auction EthUsdc price
     * @param aOsqthEthPrice auction OsqthEth price
     */
    function _getBoundaries(
        uint256 aEthUsdcPrice,
        uint256 aOsqthEthPrice,
        bool isPosIVbump,
        uint256 expIVbump
    ) internal view returns (Constants.Boundaries memory) {
        int24 tickSpacing = IVaultStorage(vaultStorage).tickSpacing();
        //const = 2^96
        int24 tickFloorEthUsdc = _floor(
            IUniswapMath(uniswapMath).getTickAtSqrtRatio(
                _toUint160(((uint256(1e30).div(aEthUsdcPrice)).sqrt()).mul(79228162514264337593543950336))
            ),
            tickSpacing
        );

        int24 tickFloorOsqthEth = _floor(
            IUniswapMath(uniswapMath).getTickAtSqrtRatio(
                _toUint160(((uint256(1e18).div(aOsqthEthPrice)).sqrt()).mul(79228162514264337593543950336))
            ),
            tickSpacing
        );

        //base thresholds
        int24 baseThreshold = IVaultStorage(vaultStorage).baseThreshold();

        //iv adj parameter
        int24 tickAdj;
        {
            int24 baseAdj = toInt24(
                int256(
                    (((expIVbump - uint256(1e18)).div(IVaultStorage(vaultStorage).adjParam())).floor() *
                        uint256(int256(tickSpacing))).div(1e36)
                )
            );
            tickAdj = baseAdj < int24(120) ? int24(120) : baseAdj;
        }

        if (isPosIVbump) {
            return
                Constants.Boundaries(
                    tickFloorEthUsdc - baseThreshold - tickAdj,
                    tickFloorEthUsdc + tickSpacing + baseThreshold - tickAdj,
                    tickFloorOsqthEth - baseThreshold - tickAdj,
                    tickFloorOsqthEth + tickSpacing + baseThreshold - tickAdj
                );
        } else {
            return
                Constants.Boundaries(
                    tickFloorEthUsdc - baseThreshold + tickAdj,
                    tickFloorEthUsdc + tickSpacing + baseThreshold + tickAdj,
                    tickFloorOsqthEth - baseThreshold + tickAdj,
                    tickFloorOsqthEth + tickSpacing + baseThreshold + tickAdj
                );
        }
    }

    /// @dev exchange tokens with keeper
    function _swapWithKeeper(
        uint256 balance,
        uint256 target,
        uint256 minAmount,
        address coin,
        address keeper
    ) internal {
        if (target >= balance) {
            IERC20(coin).transferFrom(keeper, vaultTreasury, target.sub(balance).add(10));
        } else {
            uint256 amount = balance.sub(target).sub(10);
            require(amount >= minAmount, "C21");

            IVaultTreasury(vaultTreasury).transfer(IERC20(coin), keeper, amount);
        }
    }

    /**
     * @notice external function to get all auction parameters
     * @param _auctionTriggerTime timestamp when auction started
     * @return targetEth target amount of ETH
     * @return targetUsdc target amount of USDC
     * @return targetOsqth target amount of Osqth
     * @return ethBalance current ETH balance
     * @return usdcBalance current USDC balance
     * @return osqthBalance current Osqth balance
     */
    function getAuctionParams(uint256 _auctionTriggerTime)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Constants.AuctionParams memory auctionDetails = _getAuctionParams(_auctionTriggerTime);

        (uint256 targetEth, uint256 targetUsdc, uint256 targetOsqth) = _getTargets(
            auctionDetails.boundaries,
            auctionDetails.liquidityEthUsdc,
            auctionDetails.liquidityOsqthEth
        );

        (uint256 ethBalance, uint256 usdcBalance, uint256 osqthBalance) = IVaultMath(vaultMath).getTotalAmounts();

        return (targetEth, targetUsdc, targetOsqth, ethBalance, usdcBalance, osqthBalance);
    }

    /// @dev Rounds tick down towards negative infinity so that it's a multiple
    /// of `tickSpacing`.
    function _floor(int24 tick, int24 tickSpacing) internal pure returns (int24) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--;
        return compressed * tickSpacing;
    }

    /// @dev Casts uint256 to uint160 with overflow check.
    function _toUint160(uint256 x) internal pure returns (uint160) {
        assert(x <= type(uint160).max);
        return uint160(x);
    }

    /// @dev Casts int256 to int24 with overflow check.
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "C18");
        return int24(value);
    }
}