// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import {
    IUniswapV3MintCallback
} from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import {
    IUniswapV3Pool
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {
    IUniswapV3Factory,
    ArrakisV2Storage,
    IERC20,
    SafeERC20,
    EnumerableSet,
    Range,
    Rebalance
} from "./abstract/ArrakisV2Storage.sol";
import {FullMath} from "@arrakisfi/v3-lib-0.8/contracts/LiquidityAmounts.sol";
import {Withdraw, UnderlyingPayload} from "./structs/SArrakisV2.sol";
import {Position} from "./libraries/Position.sol";
import {Pool} from "./libraries/Pool.sol";
import {Underlying as UnderlyingHelper} from "./libraries/Underlying.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {hundredPercent} from "./constants/CArrakisV2.sol";

/// @title ArrakisV2 LP vault version 2
/// @notice Smart contract managing liquidity providing strategy for a given token pair
/// using multiple Uniswap V3 LP positions on multiple fee tiers.
/// @author Arrakis Finance
/// @dev DO NOT ADD STATE VARIABLES - APPEND THEM TO ArrakisV2Storage
contract ArrakisV2 is IUniswapV3MintCallback, ArrakisV2Storage {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // solhint-disable-next-line no-empty-blocks
    constructor(IUniswapV3Factory factory_) ArrakisV2Storage(factory_) {}

    /// @notice Uniswap V3 callback fn, called back on pool.mint
    function uniswapV3MintCallback(
        uint256 amount0Owed_,
        uint256 amount1Owed_,
        bytes calldata /*_data*/
    ) external override {
        _uniswapV3CallBack(amount0Owed_, amount1Owed_);
    }

    /// @notice mint Arrakis V2 shares by depositing underlying
    /// @param mintAmount_ represent the amount of Arrakis V2 shares to mint.
    /// @param receiver_ address that will receive Arrakis V2 shares.
    /// @return amount0 amount of token0 needed to mint mintAmount_ of shares.
    /// @return amount1 amount of token1 needed to mint mintAmount_ of shares.
    // solhint-disable-next-line function-max-lines, code-complexity
    function mint(uint256 mintAmount_, address receiver_)
        external
        nonReentrant
        returns (uint256 amount0, uint256 amount1)
    {
        require(mintAmount_ > 0, "MA");
        require(
            restrictedMint == address(0) || msg.sender == restrictedMint,
            "R"
        );
        address me = address(this);
        uint256 ts = totalSupply();
        bool isTotalSupplyGtZero = ts > 0;
        if (isTotalSupplyGtZero) {
            (uint256 current0, uint256 current1, , ) = UnderlyingHelper
                .totalUnderlyingWithFees(
                    UnderlyingPayload({
                        ranges: _ranges,
                        factory: factory,
                        token0: address(token0),
                        token1: address(token1),
                        self: me
                    })
                );

            /// @dev current0 and current1 include fees and leftover (but not manager balances)
            amount0 = FullMath.mulDivRoundingUp(mintAmount_, current0, ts);
            amount1 = FullMath.mulDivRoundingUp(mintAmount_, current1, ts);
        } else {
            uint256 denominator = 1 ether;
            uint256 init0M = init0;
            uint256 init1M = init1;

            amount0 = FullMath.mulDivRoundingUp(
                mintAmount_,
                init0M,
                denominator
            );
            amount1 = FullMath.mulDivRoundingUp(
                mintAmount_,
                init1M,
                denominator
            );

            /// @dev check ratio against precision attacks (small values that skew init ratio)
            uint256 amount0Mint = init0M != 0
                ? FullMath.mulDiv(amount0, denominator, init0M)
                : type(uint256).max;
            uint256 amount1Mint = init1M != 0
                ? FullMath.mulDiv(amount1, denominator, init1M)
                : type(uint256).max;

            require(
                (amount0Mint < amount1Mint ? amount0Mint : amount1Mint) ==
                    mintAmount_,
                "A0&A1"
            );
        }

        _mint(receiver_, mintAmount_);

        // transfer amounts owed to contract
        if (amount0 > 0) {
            token0.safeTransferFrom(msg.sender, me, amount0);
        }
        if (amount1 > 0) {
            token1.safeTransferFrom(msg.sender, me, amount1);
        }

        if (isTotalSupplyGtZero) {
            for (uint256 i; i < _ranges.length; i++) {
                Range memory range = _ranges[i];
                IUniswapV3Pool pool = IUniswapV3Pool(
                    factory.getPool(
                        address(token0),
                        address(token1),
                        range.feeTier
                    )
                );
                uint128 liquidity = Position.getLiquidityByRange(
                    pool,
                    me,
                    range.lowerTick,
                    range.upperTick
                );
                if (liquidity == 0) continue;

                liquidity = SafeCast.toUint128(
                    FullMath.mulDiv(liquidity, mintAmount_, ts)
                );

                pool.mint(me, range.lowerTick, range.upperTick, liquidity, "");
            }
        }

        emit LogMint(receiver_, mintAmount_, amount0, amount1);
    }

    /// @notice burn Arrakis V2 shares and withdraw underlying.
    /// @param burnAmount_ amount of vault shares to burn.
    /// @param receiver_ address to receive underlying tokens withdrawn.
    /// @return amount0 amount of token0 sent to receiver
    /// @return amount1 amount of token1 sent to receiver
    // solhint-disable-next-line function-max-lines
    function burn(uint256 burnAmount_, address receiver_)
        external
        nonReentrant
        returns (uint256 amount0, uint256 amount1)
    {
        require(burnAmount_ > 0, "BA");

        uint256 ts = totalSupply();
        require(ts > 0, "TS");

        _burn(msg.sender, burnAmount_);

        Withdraw memory total;

        for (uint256 i; i < _ranges.length; i++) {
            Range memory range = _ranges[i];
            IUniswapV3Pool pool = IUniswapV3Pool(
                factory.getPool(address(token0), address(token1), range.feeTier)
            );
            uint128 liquidity = Position.getLiquidityByRange(
                pool,
                address(this),
                range.lowerTick,
                range.upperTick
            );
            if (liquidity == 0) continue;

            liquidity = SafeCast.toUint128(
                FullMath.mulDiv(liquidity, burnAmount_, ts)
            );

            Withdraw memory withdraw = _withdraw(
                pool,
                range.lowerTick,
                range.upperTick,
                liquidity
            );

            total.fee0 += withdraw.fee0;
            total.fee1 += withdraw.fee1;

            total.burn0 += withdraw.burn0;
            total.burn1 += withdraw.burn1;
        }

        _applyFees(total.fee0, total.fee1);

        uint256 leftOver0 = token0.balanceOf(address(this)) -
            managerBalance0 -
            total.burn0;
        uint256 leftOver1 = token1.balanceOf(address(this)) -
            managerBalance1 -
            total.burn1;

        // the proportion of user balance.
        amount0 = FullMath.mulDiv(leftOver0, burnAmount_, ts);
        amount1 = FullMath.mulDiv(leftOver1, burnAmount_, ts);

        amount0 += total.burn0;
        amount1 += total.burn1;

        if (amount0 > 0) {
            token0.safeTransfer(receiver_, amount0);
        }

        if (amount1 > 0) {
            token1.safeTransfer(receiver_, amount1);
        }

        // For monitoring how much user burn LP token for getting their token back.
        emit LPBurned(msg.sender, total.burn0, total.burn1);
        emit LogCollectedFees(total.fee0, total.fee1);
        emit LogBurn(receiver_, burnAmount_, amount0, amount1);
    }

    /// @notice rebalance ArrakisV2 vault's UniswapV3 positions
    /// @param rebalanceParams_ rebalance params, containing ranges where
    /// we need to collect tokens and ranges where we need to mint liquidity.
    /// Also contain swap payload to changes token0/token1 proportion.
    /// @dev only Manager contract can call this function.
    // solhint-disable-next-line function-max-lines, code-complexity
    function rebalance(Rebalance calldata rebalanceParams_)
        external
        onlyManager
        nonReentrant
    {
        // Burns.
        IUniswapV3Factory mFactory = factory;
        IERC20 mToken0 = token0;
        IERC20 mToken1 = token1;

        {
            Withdraw memory aggregator;
            for (uint256 i; i < rebalanceParams_.burns.length; i++) {
                IUniswapV3Pool pool = IUniswapV3Pool(
                    mFactory.getPool(
                        address(mToken0),
                        address(mToken1),
                        rebalanceParams_.burns[i].range.feeTier
                    )
                );

                uint128 liquidity = Position.getLiquidityByRange(
                    pool,
                    address(this),
                    rebalanceParams_.burns[i].range.lowerTick,
                    rebalanceParams_.burns[i].range.upperTick
                );

                if (liquidity == 0) continue;

                uint128 liquidityToWithdraw;

                if (rebalanceParams_.burns[i].liquidity == type(uint128).max)
                    liquidityToWithdraw = liquidity;
                else liquidityToWithdraw = rebalanceParams_.burns[i].liquidity;

                Withdraw memory withdraw = _withdraw(
                    pool,
                    rebalanceParams_.burns[i].range.lowerTick,
                    rebalanceParams_.burns[i].range.upperTick,
                    liquidityToWithdraw
                );

                if (liquidityToWithdraw == liquidity) {
                    (bool exists, uint256 index) = Position.rangeExists(
                        _ranges,
                        rebalanceParams_.burns[i].range
                    );
                    require(exists, "RRNE");

                    _ranges[index] = _ranges[_ranges.length - 1];
                    _ranges.pop();
                }

                aggregator.burn0 += withdraw.burn0;
                aggregator.burn1 += withdraw.burn1;

                aggregator.fee0 += withdraw.fee0;
                aggregator.fee1 += withdraw.fee1;
            }

            require(aggregator.burn0 >= rebalanceParams_.minBurn0, "B0");
            require(aggregator.burn1 >= rebalanceParams_.minBurn1, "B1");

            if (aggregator.fee0 > 0 || aggregator.fee1 > 0) {
                _applyFees(aggregator.fee0, aggregator.fee1);

                emit LogCollectedFees(aggregator.fee0, aggregator.fee1);
            }
        }

        // Swap.
        if (rebalanceParams_.swap.amountIn > 0) {
            require(_routers.contains(rebalanceParams_.swap.router), "NR");

            uint256 balance0Before = mToken0.balanceOf(address(this));
            uint256 balance1Before = mToken1.balanceOf(address(this));

            mToken0.safeApprove(address(rebalanceParams_.swap.router), 0);
            mToken1.safeApprove(address(rebalanceParams_.swap.router), 0);

            mToken0.safeApprove(
                address(rebalanceParams_.swap.router),
                balance0Before
            );
            mToken1.safeApprove(
                address(rebalanceParams_.swap.router),
                balance1Before
            );

            (bool success, ) = rebalanceParams_.swap.router.call(
                rebalanceParams_.swap.payload
            );
            require(success, "SC");

            uint256 balance0After = mToken0.balanceOf(address(this));
            uint256 balance1After = mToken1.balanceOf(address(this));
            if (rebalanceParams_.swap.zeroForOne) {
                require(
                    (balance1After >=
                        balance1Before +
                            rebalanceParams_.swap.expectedMinReturn) &&
                        (balance0After >=
                            balance0Before - rebalanceParams_.swap.amountIn),
                    "SF"
                );
                balance0After = balance0Before - balance0After;
                balance1After = balance1After - balance1Before;
            } else {
                require(
                    (balance0After >=
                        balance0Before +
                            rebalanceParams_.swap.expectedMinReturn) &&
                        (balance1After >=
                            balance1Before - rebalanceParams_.swap.amountIn),
                    "SF"
                );
                balance0After = balance0After - balance0Before;
                balance1After = balance1Before - balance1After;
            }
            emit LogRebalance(rebalanceParams_, balance0After, balance1After);
        } else {
            emit LogRebalance(rebalanceParams_, 0, 0);
        }

        // Mints.
        uint256 aggregator0;
        uint256 aggregator1;
        for (uint256 i; i < rebalanceParams_.mints.length; i++) {
            (bool exists, ) = Position.rangeExists(
                _ranges,
                rebalanceParams_.mints[i].range
            );
            address pool = factory.getPool(
                address(token0),
                address(token1),
                rebalanceParams_.mints[i].range.feeTier
            );
            if (!exists) {
                // check that the pool exists on Uniswap V3.

                require(pool != address(0), "NUP");
                require(_pools.contains(pool), "P");
                require(
                    Pool.validateTickSpacing(
                        pool,
                        rebalanceParams_.mints[i].range
                    ),
                    "RTS"
                );

                _ranges.push(rebalanceParams_.mints[i].range);
            }

            (uint256 amt0, uint256 amt1) = IUniswapV3Pool(pool).mint(
                address(this),
                rebalanceParams_.mints[i].range.lowerTick,
                rebalanceParams_.mints[i].range.upperTick,
                rebalanceParams_.mints[i].liquidity,
                ""
            );
            aggregator0 += amt0;
            aggregator1 += amt1;
        }
        require(aggregator0 >= rebalanceParams_.minDeposit0, "D0");
        require(aggregator1 >= rebalanceParams_.minDeposit1, "D1");

        require(token0.balanceOf(address(this)) >= managerBalance0, "MB0");
        require(token1.balanceOf(address(this)) >= managerBalance1, "MB1");
    }

    /// @notice will send manager fees to manager
    /// @dev anyone can call this function
    function withdrawManagerBalance() external nonReentrant {
        uint256 amount0 = managerBalance0;
        uint256 amount1 = managerBalance1;

        managerBalance0 = 0;
        managerBalance1 = 0;

        if (amount0 > 0) {
            token0.safeTransfer(manager, amount0);
        }

        if (amount1 > 0) {
            token1.safeTransfer(manager, amount1);
        }

        emit LogWithdrawManagerBalance(amount0, amount1);
    }

    function _withdraw(
        IUniswapV3Pool pool_,
        int24 lowerTick_,
        int24 upperTick_,
        uint128 liquidity_
    ) internal returns (Withdraw memory withdraw) {
        (withdraw.burn0, withdraw.burn1) = pool_.burn(
            lowerTick_,
            upperTick_,
            liquidity_
        );

        (uint256 collect0, uint256 collect1) = pool_.collect(
            address(this),
            lowerTick_,
            upperTick_,
            type(uint128).max,
            type(uint128).max
        );

        withdraw.fee0 = collect0 - withdraw.burn0;
        withdraw.fee1 = collect1 - withdraw.burn1;
    }

    function _applyFees(uint256 fee0_, uint256 fee1_) internal {
        uint16 mManagerFeeBPS = managerFeeBPS;
        managerBalance0 += (fee0_ * mManagerFeeBPS) / hundredPercent;
        managerBalance1 += (fee1_ * mManagerFeeBPS) / hundredPercent;
    }
}