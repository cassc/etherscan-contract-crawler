// SPDX-License-Identifier: MIT
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
    Rebalance,
    Range
} from "./abstract/ArrakisV2Storage.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {FullMath} from "@arrakisfi/v3-lib-0.8/contracts/LiquidityAmounts.sol";
import {
    Withdraw,
    UnderlyingPayload,
    BurnLiquidity,
    UnderlyingOutput
} from "./structs/SArrakisV2.sol";
import {Position} from "./libraries/Position.sol";
import {Pool} from "./libraries/Pool.sol";
import {Manager} from "./libraries/Manager.sol";
import {Underlying as UnderlyingHelper} from "./libraries/Underlying.sol";
import {UniswapV3Amounts} from "./libraries/UniswapV3Amounts.sol";

/// @dev DO NOT ADD STATE VARIABLES - APPEND THEM TO ArrakisV2Storage
contract ArrakisV2 is IUniswapV3MintCallback, ArrakisV2Storage {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor(IUniswapV3Factory factory_, address arrakisTreasury_)
        ArrakisV2Storage(factory_, arrakisTreasury_)
    {} // solhint-disable-line no-empty-blocks

    /// @notice Uniswap V3 callback fn, called back on pool.mint
    function uniswapV3MintCallback(
        uint256 amount0Owed_,
        uint256 amount1Owed_,
        bytes calldata /*_data*/
    ) external override {
        _uniswapV3CallBack(amount0Owed_, amount1Owed_);
    }

    // solhint-disable-next-line function-max-lines
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
        uint256 totalSupply = totalSupply();
        (
            uint256 current0,
            uint256 current1,
            uint256 fee0,
            uint256 fee1
        ) = totalSupply > 0
                ? UnderlyingHelper.totalUnderlyingWithFees(
                    UnderlyingPayload({
                        ranges: ranges,
                        factory: factory,
                        token0: address(token0),
                        token1: address(token1),
                        self: me
                    })
                )
                : (init0, init1, 0, 0);
        uint256 denominator = totalSupply > 0 ? totalSupply : 1 ether;
        /// @dev current0 and current1 include fees and left over.

        (current0, current1) = UniswapV3Amounts.subtractAdminFeesOnAmounts(
            fee0,
            fee1,
            Manager.getManagerFeeBPS(manager),
            arrakisFeeBPS,
            current0,
            current1
        );

        amount0 = FullMath.mulDivRoundingUp(mintAmount_, current0, denominator);
        amount1 = FullMath.mulDivRoundingUp(mintAmount_, current1, denominator);

        _mint(receiver_, mintAmount_);

        // transfer amounts owed to contract
        if (amount0 > 0) {
            token0.safeTransferFrom(msg.sender, me, amount0);
        }
        if (amount1 > 0) {
            token1.safeTransferFrom(msg.sender, me, amount1);
        }

        emit LogUncollectedFees(fee0, fee1);
        emit LogMint(receiver_, mintAmount_, amount0, amount1);
    }

    // solhint-disable-next-line function-max-lines, code-complexity
    function burn(
        BurnLiquidity[] calldata burns_,
        uint256 burnAmount_,
        address receiver_
    ) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        uint256 totalSupply = totalSupply();
        require(totalSupply > 0, "TS");

        UnderlyingOutput memory underlying;
        (
            underlying.amount0,
            underlying.amount1,
            underlying.fee0,
            underlying.fee1
        ) = UnderlyingHelper.totalUnderlyingWithFees(
            UnderlyingPayload({
                ranges: ranges,
                factory: factory,
                token0: address(token0),
                token1: address(token1),
                self: address(this)
            })
        );
        underlying.leftOver0 =
            token0.balanceOf(address(this)) -
            (managerBalance0 + arrakisBalance0);
        underlying.leftOver1 =
            token1.balanceOf(address(this)) -
            (managerBalance1 + arrakisBalance1);

        {
            (underlying.amount0, underlying.amount1) = UniswapV3Amounts
                .subtractAdminFeesOnAmounts(
                    underlying.fee0,
                    underlying.fee1,
                    Manager.getManagerFeeBPS(manager),
                    arrakisFeeBPS,
                    underlying.amount0,
                    underlying.amount1
                );

            // the proportion of user balance.
            amount0 = FullMath.mulDiv(
                underlying.amount0,
                burnAmount_,
                totalSupply
            );
            amount1 = FullMath.mulDiv(
                underlying.amount1,
                burnAmount_,
                totalSupply
            );
        }

        if (
            underlying.leftOver0 >= amount0 && underlying.leftOver1 >= amount1
        ) {
            _burn(msg.sender, burnAmount_);

            if (amount0 > 0) {
                token0.safeTransfer(receiver_, amount0);
            }

            if (amount1 > 0) {
                token1.safeTransfer(receiver_, amount1);
            }

            emit LogBurn(receiver_, burnAmount_, amount0, amount1);
            return (amount0, amount1);
        }

        // not at the begining of the function
        require(burns_.length > 0, "B");

        _burn(msg.sender, burnAmount_);

        Withdraw memory total;
        {
            for (uint256 i = 0; i < burns_.length; i++) {
                require(burns_[i].liquidity != 0, "LZ");

                Withdraw memory withdraw = _withdraw(
                    IUniswapV3Pool(
                        factory.getPool(
                            address(token0),
                            address(token1),
                            burns_[i].range.feeTier
                        )
                    ),
                    burns_[i].range.lowerTick,
                    burns_[i].range.upperTick,
                    burns_[i].liquidity
                );

                total.fee0 += withdraw.fee0;
                total.fee1 += withdraw.fee1;

                total.burn0 += withdraw.burn0;
                total.burn1 += withdraw.burn1;
            }

            _applyFees(total.fee0, total.fee1);
        }

        if (
            amount0 > 0 &&
            (token0.balanceOf(address(this)) -
                (managerBalance0 + arrakisBalance0)) -
                amount0 >=
            0
        ) {
            token0.safeTransfer(receiver_, amount0);
        }

        if (
            amount1 > 0 &&
            (token1.balanceOf(address(this)) -
                (managerBalance1 + arrakisBalance1)) -
                amount1 >=
            0
        ) {
            token1.safeTransfer(receiver_, amount1);
        }

        // For monitoring how much user burn LP token for getting their token back.
        emit LPBurned(msg.sender, total.burn0, total.burn1);
        emit LogUncollectedFees(underlying.fee0, underlying.fee1);
        emit LogCollectedFees(total.fee0, total.fee1);
        emit LogBurn(receiver_, burnAmount_, amount0, amount1);
    }

    // solhint-disable-next-line function-max-lines
    function rebalance(
        Range[] calldata ranges_,
        Rebalance calldata rebalanceParams_,
        Range[] calldata rangesToRemove_
    ) external onlyManager {
        for (uint256 i = 0; i < ranges_.length; i++) {
            (bool exist, ) = Position.rangeExist(ranges, ranges_[i]);
            require(!exist, "R");
            // check that the pool exist on Uniswap V3.
            address pool = factory.getPool(
                address(token0),
                address(token1),
                ranges_[i].feeTier
            );
            require(pool != address(0), "NUP");
            require(_pools.contains(pool), "P");
            // TODO: can reuse the pool got previously.
            require(Pool.validateTickSpacing(pool, ranges_[i]), "R");

            ranges.push(ranges_[i]);
        }
        _rebalance(rebalanceParams_);
        for (uint256 i = 0; i < rangesToRemove_.length; i++) {
            (bool exist, uint256 index) = Position.rangeExist(
                ranges,
                rangesToRemove_[i]
            );
            require(exist, "NR");

            Position.requireNotActiveRange(
                factory,
                address(this),
                address(token0),
                address(token1),
                rangesToRemove_[i]
            );

            delete ranges[index];

            for (uint256 j = index; j < ranges.length - 1; j++) {
                ranges[j] = ranges[j + 1];
            }
            ranges.pop();
        }
    }

    function withdrawManagerBalance() external {
        uint256 amount0 = managerBalance0;
        uint256 amount1 = managerBalance1;

        managerBalance0 = 0;
        managerBalance1 = 0;

        if (amount0 > 0) {
            token0.safeTransfer(address(manager), amount0);
        }

        if (amount1 > 0) {
            token1.safeTransfer(address(manager), amount1);
        }

        emit LogWithdrawManagerBalance(amount0, amount1);
    }

    function withdrawArrakisBalance() external {
        uint256 amount0 = arrakisBalance0;
        uint256 amount1 = arrakisBalance1;

        arrakisBalance0 = 0;
        arrakisBalance1 = 0;

        if (amount0 > 0) {
            token0.safeTransfer(arrakisTreasury, amount0);
        }

        if (amount1 > 0) {
            token1.safeTransfer(arrakisTreasury, amount1);
        }

        emit LogWithdrawArrakisBalance(amount0, amount1);
    }

    // solhint-disable-next-line function-max-lines, code-complexity
    function _rebalance(Rebalance calldata rebalanceParams_)
        internal
        nonReentrant
    {
        // Burns
        uint256 aggregator0 = 0;
        uint256 aggregator1 = 0;
        for (uint256 i = 0; i < rebalanceParams_.removes.length; i++) {
            address poolAddr = factory.getPool(
                address(token0),
                address(token1),
                rebalanceParams_.removes[i].range.feeTier
            );
            IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);

            Withdraw memory withdraw = _withdraw(
                pool,
                rebalanceParams_.removes[i].range.lowerTick,
                rebalanceParams_.removes[i].range.upperTick,
                rebalanceParams_.removes[i].liquidity
            );

            aggregator0 += withdraw.fee0;
            aggregator1 += withdraw.fee1;
        }

        if (aggregator0 > 0 || aggregator1 > 0) {
            _applyFees(aggregator0, aggregator1);

            emit LogCollectedFees(aggregator0, aggregator1);
        }

        // Swap

        if (rebalanceParams_.swap.amountIn > 0) {
            {
                require(!_pools.contains(rebalanceParams_.swap.pool), "NP");

                uint256 balance0Before = token0.balanceOf(address(this));
                uint256 balance1Before = token1.balanceOf(address(this));

                token0.safeApprove(address(rebalanceParams_.swap.router), 0);
                token1.safeApprove(address(rebalanceParams_.swap.router), 0);

                token0.safeApprove(
                    address(rebalanceParams_.swap.router),
                    balance0Before
                );
                token1.safeApprove(
                    address(rebalanceParams_.swap.router),
                    balance1Before
                );

                (bool success, ) = rebalanceParams_.swap.router.call(
                    rebalanceParams_.swap.payload
                );
                require(success, "SC");

                token0.safeApprove(address(rebalanceParams_.swap.router), 0);
                token1.safeApprove(address(rebalanceParams_.swap.router), 0);

                uint256 balance0After = token0.balanceOf(address(this));
                uint256 balance1After = token1.balanceOf(address(this));

                if (rebalanceParams_.swap.zeroForOne) {
                    require(
                        (balance1After >=
                            balance1Before +
                                rebalanceParams_.swap.expectedMinReturn) &&
                            (balance0After ==
                                balance0Before -
                                    rebalanceParams_.swap.amountIn),
                        "SF"
                    );
                } else {
                    require(
                        (balance0After >=
                            balance0Before +
                                rebalanceParams_.swap.expectedMinReturn) &&
                            (balance1After ==
                                balance1Before -
                                    rebalanceParams_.swap.amountIn),
                        "SF"
                    );
                }
            }
        }

        // Mints.
        aggregator0 = 0;
        aggregator1 = 0;
        for (uint256 i = 0; i < rebalanceParams_.deposits.length; i++) {
            IUniswapV3Pool pool = IUniswapV3Pool(
                factory.getPool(
                    address(token0),
                    address(token1),
                    rebalanceParams_.deposits[i].range.feeTier
                )
            );

            (bool exist, ) = Position.rangeExist(
                ranges,
                rebalanceParams_.deposits[i].range
            );
            require(exist, "NR");

            (uint256 amt0, uint256 amt1) = pool.mint(
                address(this),
                rebalanceParams_.deposits[i].range.lowerTick,
                rebalanceParams_.deposits[i].range.upperTick,
                rebalanceParams_.deposits[i].liquidity,
                ""
            );
            aggregator0 += amt0;
            aggregator1 += amt1;
        }
        require(aggregator0 >= rebalanceParams_.minDeposit0, "D0");
        require(aggregator1 >= rebalanceParams_.minDeposit1, "D1");

        emit LogRebalance(rebalanceParams_);
    }

    function _withdraw(
        IUniswapV3Pool pool_,
        int24 lowerTick_,
        int24 upperTick_,
        uint128 liquidity_
    ) internal returns (Withdraw memory withdraw) {
        uint256 preBalance0 = token0.balanceOf(address(this));
        uint256 preBalance1 = token1.balanceOf(address(this));

        (withdraw.burn0, withdraw.burn1) = pool_.burn(
            lowerTick_,
            upperTick_,
            liquidity_
        );

        pool_.collect(
            address(this),
            lowerTick_,
            upperTick_,
            type(uint128).max,
            type(uint128).max
        );

        withdraw.fee0 =
            token0.balanceOf(address(this)) -
            preBalance0 -
            withdraw.burn0;
        withdraw.fee1 =
            token1.balanceOf(address(this)) -
            preBalance1 -
            withdraw.burn1;
    }

    function _applyFees(uint256 fee0_, uint256 fee1_) internal {
        uint16 managerFeeBPS = Manager.getManagerFeeBPS(manager);
        managerBalance0 += (fee0_ * managerFeeBPS) / 10000;
        managerBalance1 += (fee1_ * managerFeeBPS) / 10000;
        arrakisBalance0 += (fee0_ * arrakisFeeBPS) / 10000;
        arrakisBalance1 += (fee1_ * arrakisFeeBPS) / 10000;
    }
}