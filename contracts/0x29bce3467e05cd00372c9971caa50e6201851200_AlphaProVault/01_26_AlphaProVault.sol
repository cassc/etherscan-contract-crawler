// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "@uniswap/v3-periphery/contracts/libraries/PositionKey.sol";

import "./AlphaProVaultFactory.sol";
import "../interfaces/IVault.sol";

/**
 * @param pool Underlying Uniswap V3 pool address
 * @param manager Address of manager who can set parameters and call rebalance
 * @param rebalanceDelegate Address of an additional wallet that can call rebalance
 * @param managerFee % Fee charge by the vault manager multiplied by 1e4
 * @param maxTotalSupply Cap on the total supply of vault shares
 * @param baseThreshold Half of the base order width in ticks
 * @param limitThreshold Limit order width in ticks
 * @param fullRangeWeight Proportion of liquidity in full range multiplied by 1e6
 * @param period Can only rebalance if this length of time (in seconds) has passed
 * @param minTickMove Can only rebalance if price has moved at least this much
 * @param maxTwapDeviation Max deviation (in ticks) from the TWAP during rebalance
 * @param twapDuration TWAP duration in seconds for maxTwapDeviation check
 * @param name name of the vault to be created
 * @param symbol symbol of the vault to be created
 * @param factory Address of AlphaProFactory contract
 */
struct VaultParams {
    address pool;
    address manager;
    uint24 managerFee;
    address rebalanceDelegate;
    uint256 maxTotalSupply;
    int24 baseThreshold;
    int24 limitThreshold;
    uint24 fullRangeWeight;
    uint32 period;
    int24 minTickMove;
    int24 maxTwapDeviation;
    uint32 twapDuration;
    string name;
    string symbol;
}

/**
 * @title   Alpha Pro Vault
 * @notice  A vault that provides liquidity on Uniswap V3.
 */
contract AlphaProVault is
    IVault,
    IUniswapV3MintCallback,
    IUniswapV3SwapCallback,
    ERC20Upgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    event Deposit(
        address indexed sender,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );
    event Withdraw(
        address indexed sender,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );
    event CollectFees(
        uint256 feesToVault0,
        uint256 feesToVault1,
        uint256 feesToProtocol0,
        uint256 feesToProtocol1,
        uint256 feesToManager0,
        uint256 feesToManager1
    );
    event Snapshot(int24 tick, uint256 totalAmount0, uint256 totalAmount1, uint256 totalSupply);
    event CollectProtocol(uint256 amount0, uint256 amount1);
    event CollectManager(uint256 amount0, uint256 amount1);

    event UpdateManager(address manager);
    event UpdatePendingManager(address manager);
    event UpdateRebalanceDelegate(address delegate);
    event UpdateManagerFee(uint24 managerFee);
    event UpdateBaseThreshold(int24 threshold);
    event UpdateLimitThreshold(int24 threshold);
    event UpdateFullRangeWeight(uint24 weight);
    event UpdatePeriod(uint32 period);
    event UpdateMinTickMove(int24 minTickMove);
    event UpdateMaxTwapDeviation(int24 maxTwapDeviation);
    event UpdateTwapDuration(uint32 twapDuration);
    event UpdateMaxTotalSupply(uint256 maxTotalSupply);

    IUniswapV3Pool public override pool;
    IERC20Upgradeable public token0;
    IERC20Upgradeable public token1;
    AlphaProVaultFactory public factory;

    uint256 public constant MINIMUM_LIQUIDITY = 1e3;

    address public override manager;
    address public override pendingManager;
    address public override rebalanceDelegate;
    uint256 public override maxTotalSupply;
    uint256 public override accruedProtocolFees0;
    uint256 public override accruedProtocolFees1;
    uint256 public override accruedManagerFees0;
    uint256 public override accruedManagerFees1;
    uint256 public override lastTimestamp;

    uint32 public override period;
    uint24 public override protocolFee;
    uint24 public override managerFee;
    uint24 public override pendingManagerFee;
    uint24 public override fullRangeWeight;
    int24 public override baseThreshold;
    int24 public override limitThreshold;
    int24 public override minTickMove;
    int24 public override tickSpacing;
    int24 public override maxTwapDeviation;
    uint32 public override twapDuration;
    int24 public override fullLower;
    int24 public override fullUpper;
    int24 public override baseLower;
    int24 public override baseUpper;
    int24 public override limitLower;
    int24 public override limitUpper;
    int24 public override lastTick;

    function initialize(VaultParams memory _params, address _factory) public initializer {
        __ERC20_init(_params.name, _params.symbol);
        __ReentrancyGuard_init();

        pool = IUniswapV3Pool(_params.pool);
        token0 = IERC20Upgradeable(pool.token0());
        token1 = IERC20Upgradeable(pool.token1());

        int24 _tickSpacing = pool.tickSpacing();
        tickSpacing = _tickSpacing;

        manager = _params.manager;
        rebalanceDelegate = _params.rebalanceDelegate;
        pendingManagerFee = _params.managerFee;
        maxTotalSupply = _params.maxTotalSupply;
        baseThreshold = _params.baseThreshold;
        limitThreshold = _params.limitThreshold;
        fullRangeWeight = _params.fullRangeWeight;
        period = _params.period;
        minTickMove = _params.minTickMove;
        maxTwapDeviation = _params.maxTwapDeviation;
        twapDuration = _params.twapDuration;

        factory = AlphaProVaultFactory(_factory);

        fullLower = (TickMath.MIN_TICK / _tickSpacing) * _tickSpacing;
        fullUpper = (TickMath.MAX_TICK / _tickSpacing) * _tickSpacing;

        _checkThreshold(_params.baseThreshold, _tickSpacing);
        _checkThreshold(_params.limitThreshold, _tickSpacing);
        require(_params.fullRangeWeight <= 1e6, "fullRangeWeight must be <= 1e6");
        require(_params.minTickMove >= 0, "minTickMove must be >= 0");
        require(_params.maxTwapDeviation >= 0, "maxTwapDeviation must be >= 0");
        require(_params.twapDuration > 0, "twapDuration must be > 0");
        require(_params.managerFee <= 20e4, "managerFee must be <= 200000");
    }

    /**
     * @notice Deposits tokens in proportion to the vault's current holdings.
     * @dev These tokens sit in the vault and are not used for liquidity on
     * Uniswap until the next rebalance. Also note it's not necessary to check
     * if user manipulated price to deposit cheaper, as the value of range
     * orders can only by manipulated higher.
     * @param amount0Desired Max amount of token0 to deposit
     * @param amount1Desired Max amount of token1 to deposit
     * @param amount0Min Revert if resulting `amount0` is less than this
     * @param amount1Min Revert if resulting `amount1` is less than this
     * @param to Recipient of shares
     * @return shares Number of shares minted
     * @return amount0 Amount of token0 deposited
     * @return amount1 Amount of token1 deposited
     */
    function deposit(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    )
        external
        override
        nonReentrant
        returns (uint256 shares, uint256 amount0, uint256 amount1)
    {
        require(amount0Desired > 0 || amount1Desired > 0, "amount0Desired or amount1Desired");
        require(to != address(0) && to != address(this), "to");

        // Poke positions so vault's current holdings are up-to-date
        _poke(fullLower, fullUpper);
        _poke(baseLower, baseUpper);
        _poke(limitLower, limitUpper);

        // Calculate amounts proportional to vault's holdings
        (shares, amount0, amount1) = _calcSharesAndAmounts(amount0Desired, amount1Desired);
        require(shares > 0, "shares");
        require(amount0 >= amount0Min, "amount0Min");
        require(amount1 >= amount1Min, "amount1Min");

        // Permanently lock the first MINIMUM_LIQUIDITY tokens
        if (totalSupply() == 0) {
            _mint(address(factory), MINIMUM_LIQUIDITY);
        }

        // Pull in tokens from sender
        if (amount0 > 0) token0.safeTransferFrom(msg.sender, address(this), amount0);
        if (amount1 > 0) token1.safeTransferFrom(msg.sender, address(this), amount1);

        // Mint shares to recipient
        _mint(to, shares);
        emit Deposit(msg.sender, to, shares, amount0, amount1);
        require(totalSupply() <= maxTotalSupply, "maxTotalSupply");
    }

    /// @dev Do zero-burns to poke a position on Uniswap so earned fees are
    /// updated. Should be called if total amounts needs to include up-to-date
    /// fees.
    function _poke(int24 tickLower, int24 tickUpper) internal {
        (uint128 liquidity, , , , ) = _position(tickLower, tickUpper);
        if (liquidity > 0) {
            pool.burn(tickLower, tickUpper, 0);
        }
    }

    /// @dev Calculates the largest possible `amount0` and `amount1` such that
    /// they're in the same proportion as total amounts, but not greater than
    /// `amount0Desired` and `amount1Desired` respectively.
    function _calcSharesAndAmounts(
        uint256 amount0Desired,
        uint256 amount1Desired
    ) internal view returns (uint256 shares, uint256 amount0, uint256 amount1) {
        uint256 totalSupply = totalSupply();
        (uint256 total0, uint256 total1) = getTotalAmounts();

        // If total supply > 0, vault can't be empty
        assert(totalSupply == 0 || total0 > 0 || total1 > 0);

        if (totalSupply == 0) {
            // For first deposit, just use the amounts desired
            amount0 = amount0Desired;
            amount1 = amount1Desired;
            shares = (amount0 > amount1 ? amount0 : amount1).sub(MINIMUM_LIQUIDITY);
        } else if (total0 == 0) {
            amount1 = amount1Desired;
            shares = amount1.mul(totalSupply).div(total1);
        } else if (total1 == 0) {
            amount0 = amount0Desired;
            shares = amount0.mul(totalSupply).div(total0);
        } else {
            uint256 cross0 = amount0Desired.mul(total1);
            uint256 cross1 = amount1Desired.mul(total0);
            uint256 cross = cross0 > cross1 ? cross1 : cross0;
            require(cross > 0, "cross");

            // Round up amounts
            amount0 = cross.sub(1).div(total1).add(1);
            amount1 = cross.sub(1).div(total0).add(1);
            shares = cross.mul(totalSupply).div(total0).div(total1);
        }
    }

    /**
     * @notice Withdraws tokens in proportion to the vault's holdings.
     * @param shares Shares burned by sender
     * @param amount0Min Revert if resulting `amount0` is smaller than this
     * @param amount1Min Revert if resulting `amount1` is smaller than this
     * @param to Recipient of tokens
     * @return amount0 Amount of token0 sent to recipient
     * @return amount1 Amount of token1 sent to recipient
     */
    function withdraw(
        uint256 shares,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external override nonReentrant returns (uint256 amount0, uint256 amount1) {
        require(shares > 0, "shares");
        require(to != address(0) && to != address(this), "to");
        uint256 totalSupply = totalSupply();

        // Burn shares
        _burn(msg.sender, shares);

        // Calculate token amounts proportional to unused balances
        amount0 = getBalance0().mul(shares).div(totalSupply);
        amount1 = getBalance1().mul(shares).div(totalSupply);

        // Withdraw proportion of liquidity from Uniswap pool
        (uint256 fullAmount0, uint256 fullAmount1) = _burnLiquidityShare(
            fullLower,
            fullUpper,
            shares,
            totalSupply
        );
        (uint256 baseAmount0, uint256 baseAmount1) = _burnLiquidityShare(
            baseLower,
            baseUpper,
            shares,
            totalSupply
        );
        (uint256 limitAmount0, uint256 limitAmount1) = _burnLiquidityShare(
            limitLower,
            limitUpper,
            shares,
            totalSupply
        );

        // Sum up total amounts owed to recipient
        amount0 = amount0.add(fullAmount0).add(baseAmount0).add(limitAmount0);
        amount1 = amount1.add(fullAmount1).add(baseAmount1).add(limitAmount1);
        require(amount0 >= amount0Min, "amount0Min");
        require(amount1 >= amount1Min, "amount1Min");

        // Push tokens to recipient
        if (amount0 > 0) token0.safeTransfer(to, amount0);
        if (amount1 > 0) token1.safeTransfer(to, amount1);

        emit Withdraw(msg.sender, to, shares, amount0, amount1);
    }

    /// @dev Withdraws share of liquidity in a range from Uniswap pool.
    function _burnLiquidityShare(
        int24 tickLower,
        int24 tickUpper,
        uint256 shares,
        uint256 totalSupply
    ) internal returns (uint256 amount0, uint256 amount1) {
        (uint128 totalLiquidity, , , , ) = _position(tickLower, tickUpper);
        uint256 liquidity = uint256(totalLiquidity).mul(shares).div(totalSupply);

        if (liquidity > 0) {
            (uint256 burned0, uint256 burned1, uint256 fees0, uint256 fees1) = _burnAndCollect(
                tickLower,
                tickUpper,
                _toUint128(liquidity)
            );

            // Add share of fees
            amount0 = burned0.add(fees0.mul(shares).div(totalSupply));
            amount1 = burned1.add(fees1.mul(shares).div(totalSupply));
        }
    }

    /**
     * @notice Updates vault's positions.
     * @dev Three orders are placed - a full-range order, a base order and a
     * limit order. The full-range order is placed first. Then the base
     * order is placed with as much remaining liquidity as possible. This order
     * should use up all of one token, leaving only the other one. This excess
     * amount is then placed as a single-sided bid or ask order.
     */
    function rebalance() external override nonReentrant {
        checkCanRebalance();
        if (rebalanceDelegate != address(0)) {
            require(
                msg.sender == manager || msg.sender == rebalanceDelegate,
                "rebalanceDelegate"
            );
        }

        // Withdraw all current liquidity from Uniswap pool
        int24 _fullLower = fullLower;
        int24 _fullUpper = fullUpper;
        {
            (uint128 fullLiquidity, , , , ) = _position(_fullLower, _fullUpper);
            (uint128 baseLiquidity, , , , ) = _position(baseLower, baseUpper);
            (uint128 limitLiquidity, , , , ) = _position(limitLower, limitUpper);
            _burnAndCollect(_fullLower, _fullUpper, fullLiquidity);
            _burnAndCollect(baseLower, baseUpper, baseLiquidity);
            _burnAndCollect(limitLower, limitUpper, limitLiquidity);
        }

        // Calculate new ranges
        (, int24 tick, , , , , ) = pool.slot0();
        int24 tickFloor = _floor(tick);
        int24 tickCeil = tickFloor + tickSpacing;

        int24 _baseLower = tickFloor - baseThreshold;
        int24 _baseUpper = tickCeil + baseThreshold;
        int24 _bidLower = tickFloor - limitThreshold;
        int24 _bidUpper = tickFloor;
        int24 _askLower = tickCeil;
        int24 _askUpper = tickCeil + limitThreshold;

        // Emit snapshot to record balances and supply
        uint256 balance0 = getBalance0();
        uint256 balance1 = getBalance1();
        emit Snapshot(tick, balance0, balance1, totalSupply());

        // Place full range order on Uniswap
        {
            uint128 maxFullLiquidity = _liquidityForAmounts(
                _fullLower,
                _fullUpper,
                balance0,
                balance1
            );
            uint128 fullLiquidity = _toUint128(
                uint256(maxFullLiquidity).mul(fullRangeWeight).div(1e6)
            );
            _mintLiquidity(_fullLower, _fullUpper, fullLiquidity);
        }

        // Place base order on Uniswap
        balance0 = getBalance0();
        balance1 = getBalance1();
        {
            uint128 baseLiquidity = _liquidityForAmounts(
                _baseLower,
                _baseUpper,
                balance0,
                balance1
            );
            _mintLiquidity(_baseLower, _baseUpper, baseLiquidity);
            (baseLower, baseUpper) = (_baseLower, _baseUpper);
        }

        // Place bid or ask order on Uniswap depending on which token is left
        balance0 = getBalance0();
        balance1 = getBalance1();
        uint128 bidLiquidity = _liquidityForAmounts(_bidLower, _bidUpper, balance0, balance1);
        uint128 askLiquidity = _liquidityForAmounts(_askLower, _askUpper, balance0, balance1);
        if (bidLiquidity > askLiquidity) {
            _mintLiquidity(_bidLower, _bidUpper, bidLiquidity);
            (limitLower, limitUpper) = (_bidLower, _bidUpper);
        } else {
            _mintLiquidity(_askLower, _askUpper, askLiquidity);
            (limitLower, limitUpper) = (_askLower, _askUpper);
        }

        lastTimestamp = block.timestamp;
        lastTick = tick;

        // Update fee only at each rebalance, so that if fee is increased
        // it won't be applied retroactively to current open positions
        protocolFee = factory.protocolFee();
        managerFee = pendingManagerFee;
    }

    function checkCanRebalance() public view override {
        uint256 _lastTimestamp = lastTimestamp;

        // check enough time has passed
        require(block.timestamp >= _lastTimestamp.add(period), "PE");

        // check price has moved enough
        (, int24 tick, , , , , ) = pool.slot0();
        int24 tickMove = tick > lastTick ? tick - lastTick : lastTick - tick;
        require(_lastTimestamp == 0 || tickMove >= minTickMove, "TM");

        // check price near twap
        int24 twap = getTwap();
        int24 twapDeviation = tick > twap ? tick - twap : twap - tick;
        require(twapDeviation <= maxTwapDeviation, "TP");

        // check price not too close to boundary
        int24 maxThreshold = baseThreshold > limitThreshold ? baseThreshold : limitThreshold;
        require(
            tick >= TickMath.MIN_TICK + maxThreshold + tickSpacing &&
                tick <= TickMath.MAX_TICK - maxThreshold - tickSpacing,
            "PB"
        );
    }

    /// @dev Fetches time-weighted average price in ticks from Uniswap pool.
    function getTwap() public view returns (int24) {
        uint32 _twapDuration = twapDuration;
        uint32[] memory secondsAgo = new uint32[](2);
        secondsAgo[0] = _twapDuration;
        secondsAgo[1] = 0;

        (int56[] memory tickCumulatives, ) = pool.observe(secondsAgo);
        return int24((tickCumulatives[1] - tickCumulatives[0]) / _twapDuration);
    }

    /// @dev Rounds tick down towards negative infinity so that it's a multiple
    /// of `tickSpacing`.
    function _floor(int24 tick) internal view returns (int24) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--;
        return compressed * tickSpacing;
    }

    function _checkThreshold(int24 threshold, int24 _tickSpacing) internal pure {
        require(threshold > 0, "threshold must be > 0");
        require(threshold <= TickMath.MAX_TICK, "threshold too high");
        require(threshold % _tickSpacing == 0, "threshold must be multiple of tickSpacing");
    }

    /// @dev Withdraws liquidity from a range and collects all fees in the
    /// process.
    function _burnAndCollect(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    )
        internal
        returns (uint256 burned0, uint256 burned1, uint256 feesToVault0, uint256 feesToVault1)
    {
        if (liquidity > 0) {
            (burned0, burned1) = pool.burn(tickLower, tickUpper, liquidity);
        }

        // Collect all owed tokens including earned fees
        (uint256 collect0, uint256 collect1) = pool.collect(
            address(this),
            tickLower,
            tickUpper,
            type(uint128).max,
            type(uint128).max
        );

        feesToVault0 = collect0.sub(burned0);
        feesToVault1 = collect1.sub(burned1);

        // Update accrued protocol fees
        uint256 _protocolFee = protocolFee;
        uint256 feesToProtocol0 = feesToVault0.mul(_protocolFee).div(1e6);
        uint256 feesToProtocol1 = feesToVault1.mul(_protocolFee).div(1e6);
        accruedProtocolFees0 = accruedProtocolFees0.add(feesToProtocol0);
        accruedProtocolFees1 = accruedProtocolFees1.add(feesToProtocol1);

        // Update accrued manager fees
        uint256 _managerFee = managerFee;
        uint256 feesToManager0;
        uint256 feesToManager1;
        if (_managerFee > 0) {
            feesToManager0 = feesToVault0.mul(_managerFee).div(1e6);
            feesToManager1 = feesToVault1.mul(_managerFee).div(1e6);
            accruedManagerFees0 = accruedManagerFees0.add(feesToManager0);
            accruedManagerFees1 = accruedManagerFees1.add(feesToManager1);
        }
        feesToVault0 = feesToVault0.sub(feesToProtocol0).sub(feesToManager0);
        feesToVault1 = feesToVault1.sub(feesToProtocol1).sub(feesToManager1);
        emit CollectFees(
            feesToVault0,
            feesToVault1,
            feesToProtocol0,
            feesToProtocol1,
            feesToManager0,
            feesToManager1
        );
    }

    /// @dev Deposits liquidity in a range on the Uniswap pool.
    function _mintLiquidity(int24 tickLower, int24 tickUpper, uint128 liquidity) internal {
        if (liquidity > 0) {
            pool.mint(address(this), tickLower, tickUpper, liquidity, "");
        }
    }

    /**
     * @notice Calculates the vault's total holdings of token0 and token1 - in
     * other words, how much of each token the vault would hold if it withdrew
     * all its liquidity from Uniswap.
     */
    function getTotalAmounts() public view override returns (uint256 total0, uint256 total1) {
        (uint256 fullAmount0, uint256 fullAmount1) = getPositionAmounts(fullLower, fullUpper);
        (uint256 baseAmount0, uint256 baseAmount1) = getPositionAmounts(baseLower, baseUpper);
        (uint256 limitAmount0, uint256 limitAmount1) = getPositionAmounts(
            limitLower,
            limitUpper
        );
        total0 = getBalance0().add(fullAmount0).add(baseAmount0).add(limitAmount0);
        total1 = getBalance1().add(fullAmount1).add(baseAmount1).add(limitAmount1);
    }

    /**
     * @notice Amounts of token0 and token1 held in vault's position. Includes
     * owed fees but excludes the proportion of fees that will be paid to the
     * protocol. Doesn't include fees accrued since last poke.
     */
    function getPositionAmounts(
        int24 tickLower,
        int24 tickUpper
    ) public view returns (uint256 amount0, uint256 amount1) {
        (uint128 liquidity, , , uint128 tokensOwed0, uint128 tokensOwed1) = _position(
            tickLower,
            tickUpper
        );
        (amount0, amount1) = _amountsForLiquidity(tickLower, tickUpper, liquidity);

        // Subtract protocol and manager fees
        uint256 oneMinusFee = uint256(1e6).sub(protocolFee).sub(managerFee);
        amount0 = amount0.add(uint256(tokensOwed0).mul(oneMinusFee).div(1e6));
        amount1 = amount1.add(uint256(tokensOwed1).mul(oneMinusFee).div(1e6));
    }

    /**
     * @notice Balance of token0 in vault not used in any position.
     */
    function getBalance0() public view override returns (uint256) {
        return
            token0.balanceOf(address(this)).sub(accruedProtocolFees0).sub(accruedManagerFees0);
    }

    /**
     * @notice Balance of token1 in vault not used in any position.
     */
    function getBalance1() public view override returns (uint256) {
        return
            token1.balanceOf(address(this)).sub(accruedProtocolFees1).sub(accruedManagerFees1);
    }

    /// @dev Wrapper around `IUniswapV3Pool.positions()`.
    function _position(
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (uint128, uint256, uint256, uint128, uint128) {
        bytes32 positionKey = PositionKey.compute(address(this), tickLower, tickUpper);
        return pool.positions(positionKey);
    }

    /// @dev Wrapper around `LiquidityAmounts.getAmountsForLiquidity()`.
    function _amountsForLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal view returns (uint256, uint256) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity
            );
    }

    /// @dev Wrapper around `LiquidityAmounts.getLiquidityForAmounts()`.
    function _liquidityForAmounts(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) internal view returns (uint128) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return
            LiquidityAmounts.getLiquidityForAmounts(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                amount0,
                amount1
            );
    }

    /// @dev Casts uint256 to uint128 with overflow check.
    function _toUint128(uint256 x) internal pure returns (uint128) {
        assert(x <= type(uint128).max);
        return uint128(x);
    }

    /// @dev Callback for Uniswap V3 pool.
    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        require(msg.sender == address(pool));
        if (amount0 > 0) token0.safeTransfer(msg.sender, amount0);
        if (amount1 > 0) token1.safeTransfer(msg.sender, amount1);
    }

    /// @dev Callback for Uniswap V3 pool.
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        require(msg.sender == address(pool));
        if (amount0Delta > 0) token0.safeTransfer(msg.sender, uint256(amount0Delta));
        if (amount1Delta > 0) token1.safeTransfer(msg.sender, uint256(amount1Delta));
    }

    /**
     * @notice Used to collect accumulated protocol fees.
     */
    function collectProtocol(address to) external {
        require(msg.sender == factory.governance(), "governance");
        uint256 _accruedProtocolFees0 = accruedProtocolFees0;
        uint256 _accruedProtocolFees1 = accruedProtocolFees1;
        accruedProtocolFees0 = 0;
        accruedProtocolFees1 = 0;
        if (_accruedProtocolFees0 > 0) token0.safeTransfer(to, _accruedProtocolFees0);
        if (_accruedProtocolFees1 > 0) token1.safeTransfer(to, _accruedProtocolFees1);
        emit CollectProtocol(_accruedProtocolFees0, _accruedProtocolFees1);
    }

    /*
     * @notice Used to collect accumulated manager fees.
     */
    function collectManager(address to) external onlyManager {
        uint256 _accruedManagerFees0 = accruedManagerFees0;
        uint256 _accruedManagerFees1 = accruedManagerFees1;
        accruedManagerFees0 = 0;
        accruedManagerFees1 = 0;
        if (_accruedManagerFees0 > 0) token0.safeTransfer(to, _accruedManagerFees0);
        if (_accruedManagerFees1 > 0) token1.safeTransfer(to, _accruedManagerFees1);
        emit CollectManager(_accruedManagerFees0, _accruedManagerFees1);
    }

    /**
     * @notice Removes tokens accidentally sent to this vault.
     */
    function sweep(IERC20Upgradeable token, uint256 amount, address to) external onlyManager {
        require(token != token0 && token != token1, "token");
        token.safeTransfer(to, amount);
    }

    function setBaseThreshold(int24 _baseThreshold) external onlyManager {
        _checkThreshold(_baseThreshold, tickSpacing);
        baseThreshold = _baseThreshold;
        emit UpdateBaseThreshold(_baseThreshold);
    }

    function setLimitThreshold(int24 _limitThreshold) external onlyManager {
        _checkThreshold(_limitThreshold, tickSpacing);
        limitThreshold = _limitThreshold;
        emit UpdateLimitThreshold(_limitThreshold);
    }

    function setFullRangeWeight(uint24 _fullRangeWeight) external onlyManager {
        require(_fullRangeWeight <= 1e6, "fullRangeWeight must be <= 1e6");
        fullRangeWeight = _fullRangeWeight;
        emit UpdateFullRangeWeight(_fullRangeWeight);
    }

    function setPeriod(uint32 _period) external onlyManager {
        period = _period;
        emit UpdatePeriod(_period);
    }

    function setMinTickMove(int24 _minTickMove) external onlyManager {
        require(_minTickMove >= 0, "minTickMove must be >= 0");
        minTickMove = _minTickMove;
        emit UpdateMinTickMove(_minTickMove);
    }

    function setMaxTwapDeviation(int24 _maxTwapDeviation) external onlyManager {
        require(_maxTwapDeviation >= 0, "maxTwapDeviation must be >= 0");
        maxTwapDeviation = _maxTwapDeviation;
        emit UpdateMaxTwapDeviation(_maxTwapDeviation);
    }

    function setTwapDuration(uint32 _twapDuration) external onlyManager {
        require(_twapDuration > 0, "twapDuration must be > 0");
        twapDuration = _twapDuration;
        emit UpdateTwapDuration(_twapDuration);
    }

    /**
     * @notice Used to change deposit cap for a guarded launch or to ensure
     * vault doesn't grow too large relative to the pool. Cap is on total
     * supply rather than amounts of token0 and token1 as those amounts
     * fluctuate naturally over time.
     */
    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyManager {
        maxTotalSupply = _maxTotalSupply;
        emit UpdateMaxTotalSupply(_maxTotalSupply);
    }

    /**
     * @notice Removes liquidity in case of emergency.
     */
    function emergencyBurn(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external onlyManager {
        pool.burn(tickLower, tickUpper, liquidity);
        pool.collect(address(this), tickLower, tickUpper, type(uint128).max, type(uint128).max);
    }

    /**
     * @notice Manager address is not updated until the new manager
     * address has called `acceptManager()` to accept this responsibility.
     */
    function setManager(address _manager) external onlyManager {
        pendingManager = _manager;
        emit UpdatePendingManager(_manager);
    }

    function setRebalanceDelegate(address _rebalanceDelegate) external onlyManager {
        rebalanceDelegate = _rebalanceDelegate;
        emit UpdateRebalanceDelegate(_rebalanceDelegate);
    }

    /**
     * @notice Change the manager fee charged on pool fees earned from
     * Uniswap, expressed as multiple of 1e-6. Fee is hard capped at 20%.
     */
    function setManagerFee(uint24 _pendingManagerFee) external onlyManager {
        require(_pendingManagerFee <= 20e4, "managerFee must be <= 200000");
        pendingManagerFee = _pendingManagerFee;
        emit UpdateManagerFee(_pendingManagerFee);
    }

    /**
     * @notice `setManager()` should be called by the existing manager
     * address prior to calling this function.
     */
    function acceptManager() external {
        require(msg.sender == pendingManager, "pendingManager");
        manager = msg.sender;
        emit UpdateManager(msg.sender);
    }

    modifier onlyManager() {
        require(msg.sender == manager, "manager");
        _;
    }
}