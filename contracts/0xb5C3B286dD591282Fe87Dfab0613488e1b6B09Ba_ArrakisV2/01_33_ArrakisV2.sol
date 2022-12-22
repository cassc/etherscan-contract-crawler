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
    Rebalance,
    Range
} from "./abstract/ArrakisV2Storage.sol";
import {FullMath} from "@arrakisfi/v3-lib-0.8/contracts/LiquidityAmounts.sol";
import {
    Withdraw,
    UnderlyingPayload,
    BurnLiquidity,
    UnderlyingOutput
} from "./structs/SArrakisV2.sol";
import {Position} from "./libraries/Position.sol";
import {Pool} from "./libraries/Pool.sol";
import {Underlying as UnderlyingHelper} from "./libraries/Underlying.sol";
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
        uint256 ts = totalSupply();
        bool isTotalSupplyGtZero = ts > 0;
        (
            uint256 current0,
            uint256 current1,
            uint256 fee0,
            uint256 fee1
        ) = isTotalSupplyGtZero
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
        uint256 denominator = isTotalSupplyGtZero ? ts : 1 ether;

        /// @dev current0 and current1 include fees and left over (but not manager balances)
        amount0 = FullMath.mulDivRoundingUp(mintAmount_, current0, denominator);
        amount1 = FullMath.mulDivRoundingUp(mintAmount_, current1, denominator);

        if (!isTotalSupplyGtZero) {
            uint256 amount0Mint = current0 != 0
                ? FullMath.mulDiv(amount0, denominator, current0)
                : type(uint256).max;
            uint256 amount1Mint = current1 != 0
                ? FullMath.mulDiv(amount1, denominator, current1)
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

        emit LogUncollectedFees(fee0, fee1);
        emit LogMint(receiver_, mintAmount_, amount0, amount1);
    }

    /// @notice burn Arrakis V2 shares and withdraw underlying.
    /// @param burns_ ranges to burn liquidity from and collect underlying.
    /// @param burnAmount_ amount of vault shares to burn.
    /// @param receiver_ address to receive underlying tokens withdrawn.
    /// @return amount0 amount of token0 sent to receiver
    /// @return amount1 amount of token1 sent to receiver
    // solhint-disable-next-line function-max-lines, code-complexity
    function burn(
        BurnLiquidity[] calldata burns_,
        uint256 burnAmount_,
        address receiver_
    ) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        require(burnAmount_ > 0, "BA");

        uint256 ts = totalSupply();
        require(ts > 0, "TS");

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
            managerBalance0;
        underlying.leftOver1 =
            token1.balanceOf(address(this)) -
            managerBalance1;

        {
            // the proportion of user balance.
            amount0 = FullMath.mulDiv(underlying.amount0, burnAmount_, ts);
            amount1 = FullMath.mulDiv(underlying.amount1, burnAmount_, ts);
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
            for (uint256 i; i < burns_.length; i++) {
                require(burns_[i].liquidity != 0, "LZ");
                {
                    (bool exist, ) = Position.rangeExist(
                        ranges,
                        burns_[i].range
                    );
                    require(exist, "RRNE");
                }

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

        if (amount0 > 0) {
            token0.safeTransfer(receiver_, amount0);
        }

        if (amount1 > 0) {
            token1.safeTransfer(receiver_, amount1);
        }

        // intentional underflow revert if managerBalance > contract's token balance
        {
            uint256 leftover0 = token0.balanceOf(address(this)) -
                managerBalance0;
            uint256 leftover1 = token1.balanceOf(address(this)) -
                managerBalance1;
            (
                uint256 fee0AfterManagerFee,
                uint256 fee1AfterManagerFee
            ) = UnderlyingHelper.subtractAdminFees(
                    total.fee0,
                    total.fee1,
                    managerFeeBPS
                );

            require(
                (fee0AfterManagerFee >= leftover0 ||
                    leftover0 - fee0AfterManagerFee <= underlying.leftOver0) ||
                    ((leftover0 - fee0AfterManagerFee - underlying.leftOver0) <=
                        FullMath.mulDiv(
                            total.burn0,
                            _burnBuffer,
                            hundredPercent
                        )),
                "L0"
            );
            require(
                (fee1AfterManagerFee >= leftover1 ||
                    leftover1 - fee1AfterManagerFee <= underlying.leftOver1) ||
                    ((leftover1 - fee1AfterManagerFee - underlying.leftOver1) <=
                        FullMath.mulDiv(
                            total.burn1,
                            _burnBuffer,
                            hundredPercent
                        )),
                "L1"
            );
        }

        // For monitoring how much user burn LP token for getting their token back.
        emit LPBurned(msg.sender, total.burn0, total.burn1);
        emit LogUncollectedFees(underlying.fee0, underlying.fee1);
        emit LogCollectedFees(total.fee0, total.fee1);
        emit LogBurn(receiver_, burnAmount_, amount0, amount1);
    }

    /// @notice rebalance ArrakisV2 vault's UniswapV3 positions
    /// @param rangesToAdd_ list of new ranges to initialize (add to ranges array).
    /// @param rebalanceParams_ rebalance params, containing ranges where
    /// we need to collect tokens and ranges where we need to mint tokens.
    /// Also contain swap payload to changes token0/token1 proportion.
    /// @param rangesToRemove_ list of ranges to remove from ranges array (only when liquidity==0)
    /// @dev only Manager contract can call this contract.
    // solhint-disable-next-line function-max-lines
    function rebalance(
        Range[] calldata rangesToAdd_,
        Rebalance calldata rebalanceParams_,
        Range[] calldata rangesToRemove_
    ) external onlyManager {
        for (uint256 i; i < rangesToAdd_.length; i++) {
            (bool exist, ) = Position.rangeExist(ranges, rangesToAdd_[i]);
            require(!exist, "NRRE");
            // check that the pool exist on Uniswap V3.
            address pool = factory.getPool(
                address(token0),
                address(token1),
                rangesToAdd_[i].feeTier
            );
            require(pool != address(0), "NUP");
            require(_pools.contains(pool), "P");
            require(Pool.validateTickSpacing(pool, rangesToAdd_[i]), "RTS");

            ranges.push(rangesToAdd_[i]);
        }
        _rebalance(rebalanceParams_);
        require(token0.balanceOf(address(this)) >= managerBalance0, "MB0");
        require(token1.balanceOf(address(this)) >= managerBalance1, "MB1");
        for (uint256 i; i < rangesToRemove_.length; i++) {
            (bool exist, uint256 index) = Position.rangeExist(
                ranges,
                rangesToRemove_[i]
            );
            require(exist, "RRNE");

            Position.requireNotActiveRange(
                factory,
                address(this),
                address(token0),
                address(token1),
                rangesToRemove_[i]
            );

            ranges[index] = ranges[ranges.length - 1];
            ranges.pop();
        }
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

    // solhint-disable-next-line function-max-lines, code-complexity
    function _rebalance(Rebalance calldata rebalanceParams_)
        internal
        nonReentrant
    {
        // Burns.
        IUniswapV3Factory mFactory = factory;
        address mToken0Addr = address(token0);
        address mToken1Addr = address(token1);

        {
            Withdraw memory aggregator;
            for (uint256 i; i < rebalanceParams_.removes.length; i++) {
                address poolAddr = mFactory.getPool(
                    mToken0Addr,
                    mToken1Addr,
                    rebalanceParams_.removes[i].range.feeTier
                );
                IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);

                Withdraw memory withdraw = _withdraw(
                    pool,
                    rebalanceParams_.removes[i].range.lowerTick,
                    rebalanceParams_.removes[i].range.upperTick,
                    rebalanceParams_.removes[i].liquidity
                );

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
            {
                require(_routers.contains(rebalanceParams_.swap.router), "NR");

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

                uint256 balance0After = token0.balanceOf(address(this));
                uint256 balance1After = token1.balanceOf(address(this));

                if (rebalanceParams_.swap.zeroForOne) {
                    require(
                        (balance1After >=
                            balance1Before +
                                rebalanceParams_.swap.expectedMinReturn) &&
                            (balance0After >=
                                balance0Before -
                                    rebalanceParams_.swap.amountIn),
                        "SF"
                    );
                } else {
                    require(
                        (balance0After >=
                            balance0Before +
                                rebalanceParams_.swap.expectedMinReturn) &&
                            (balance1After >=
                                balance1Before -
                                    rebalanceParams_.swap.amountIn),
                        "SF"
                    );
                }
            }
        }

        // Mints.
        uint256 aggregator0;
        uint256 aggregator1;
        for (uint256 i; i < rebalanceParams_.deposits.length; i++) {
            IUniswapV3Pool pool = IUniswapV3Pool(
                mFactory.getPool(
                    mToken0Addr,
                    mToken1Addr,
                    rebalanceParams_.deposits[i].range.feeTier
                )
            );

            (bool exist, ) = Position.rangeExist(
                ranges,
                rebalanceParams_.deposits[i].range
            );
            require(exist, "DRE");

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