// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

import "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";
import "@yield-protocol/utils-v2/contracts/token/SafeERC20Namer.sol";
import "@yield-protocol/utils-v2/contracts/token/MinimalTransferHelper.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "@yield-protocol/utils-v2/contracts/token/ERC20Rewards.sol";
import "@yield-protocol/utils-v2/contracts/cast/CastU256I128.sol";
import "@yield-protocol/utils-v2/contracts/cast/CastU128I128.sol";
import "@yield-protocol/vault-interfaces/DataTypes.sol";
import "@yield-protocol/vault-interfaces/ICauldron.sol";
import "@yield-protocol/vault-interfaces/ILadle.sol";
import "@yield-protocol/yieldspace-interfaces/IPool.sol";
import "@yield-protocol/yieldspace-v2/contracts/extensions/YieldMathExtensions.sol";


library DivUp {
    function divUp(uint256 a, uint256 b) internal pure returns(uint256 c) {
        a % b == 0 ? c = a / b : c = a / b + 1;
    }
}

/// @dev The Pool contract exchanges base for fyToken at a price defined by a specific formula.
contract Strategy is AccessControl, ERC20Rewards {
    using DivUp for uint256;
    using MinimalTransferHelper for IERC20;
    using YieldMathExtensions for IPool;
    using CastU256U128 for uint256; // Inherited from ERC20Rewards
    using CastU256I128 for uint256;
    using CastU128I128 for uint128;

    event YieldSet(ILadle ladle, ICauldron cauldron);
    event TokenJoinReset(address join);
    event TokenIdSet(bytes6 id);
    event NextPoolSet(IPool indexed pool, bytes6 indexed seriesId);
    event PoolEnded(address pool);
    event PoolStarted(address pool);

    IERC20 public immutable base;                // Base token for this strategy
    bytes6 public baseId;                        // Identifier for the base token in Yieldv2
    address public baseJoin;                     // Yield v2 Join to deposit token when borrowing
    ILadle public ladle;                         // Gateway to the Yield v2 Collateralized Debt Engine
    ICauldron public cauldron;                   // Accounts in the Yield v2 Collateralized Debt Engine

    IPool public pool;                           // Current pool that this strategy invests in
    bytes6 public seriesId;                      // SeriesId for the current pool in Yield v2
    IFYToken public fyToken;                     // Current fyToken for this strategy

    IPool public nextPool;                       // Next pool that this strategy will invest in
    bytes6 public nextSeriesId;                  // SeriesId for the next pool in Yield v2

    uint256 public cached;                       // LP tokens owned by the strategy after the last operation
    mapping (address => uint128) public invariants; // Value of pool invariant at start time

    constructor(string memory name, string memory symbol, ILadle ladle_, IERC20 base_, bytes6 baseId_)
        ERC20Rewards(name, symbol, SafeERC20Namer.tokenDecimals(address(base_))) 
    { // The strategy asset inherits the decimals of its base, that matches the decimals of the fyToken and pool
        require(
            ladle_.cauldron().assets(baseId_) == address(base_),
            "Mismatched baseId"
        );
        base = base_;
        baseId = baseId_;
        baseJoin = address(ladle_.joins(baseId_));

        ladle = ladle_;
        cauldron = ladle_.cauldron();
    }

    modifier poolSelected() {
        require (
            pool != IPool(address(0)),
            "Pool not selected"
        );
        _;
    }

    modifier poolNotSelected() {
        require (
            pool == IPool(address(0)),
            "Pool selected"
        );
        _;
    }

    modifier afterMaturity() {
        require (
            uint32(block.timestamp) >= fyToken.maturity(),
            "Only after maturity"
        );
        _;
    }

    /// @dev Set a new Ladle and Cauldron
    /// @notice Use with extreme caution, only for Ladle replacements
    function setYield(ILadle ladle_)
        external
        poolNotSelected
        auth
    {
        ladle = ladle_;
        ICauldron cauldron_ = ladle_.cauldron();
        cauldron = cauldron_;
        emit YieldSet(ladle_, cauldron_);
    }

    /// @dev Set a new base token id
    /// @notice Use with extreme caution, only for token reconfigurations in Cauldron
    function setTokenId(bytes6 baseId_)
        external
        poolNotSelected
        auth
    {
        require(
            ladle.cauldron().assets(baseId_) == address(base),
            "Mismatched baseId"
        );
        baseId = baseId_;
        emit TokenIdSet(baseId_);
    }

    /// @dev Reset the base token join
    /// @notice Use with extreme caution, only for Join replacements
    function resetTokenJoin()
        external
        poolNotSelected
        auth
    {
        baseJoin = address(ladle.joins(baseId));
        emit TokenJoinReset(baseJoin);
    }

    /// @dev Set the next pool to invest in
    function setNextPool(IPool pool_, bytes6 seriesId_) 
        external
        auth
    {
        require(
            base == pool_.base(),
            "Mismatched base"
        );
        DataTypes.Series memory series = cauldron.series(seriesId_);
        require(
            series.fyToken == pool_.fyToken(),
            "Mismatched seriesId"
        );

        nextPool = pool_;
        nextSeriesId = seriesId_;

        emit NextPoolSet(pool_, seriesId_);
    }

    /// @dev Start the strategy investments in the next pool
    /// @param minRatio Minimum allowed ratio between the reserves of the next pool, as a fixed point number with 18 decimals (base/fyToken)
    /// @param maxRatio Maximum allowed ratio between the reserves of the next pool, as a fixed point number with 18 decimals (base/fyToken)
    /// @notice When calling this function for the first pool, some underlying needs to be transferred to the strategy first, using a batchable router.
    function startPool(uint256 minRatio, uint256 maxRatio)
        external
        auth
        poolNotSelected
    {
        IPool nextPool_ = nextPool;
        require(nextPool_ != IPool(address(0)), "Next pool not set");

        // Caching
        IPool pool_ = nextPool_;
        IFYToken fyToken_ = pool_.fyToken();
        bytes6 seriesId_ = nextSeriesId;

        pool = pool_;
        fyToken = fyToken_;
        seriesId = seriesId_;

        delete nextPool;
        delete nextSeriesId;

        // Find pool proportion p = tokenReserves/(tokenReserves + fyTokenReserves)
        // Deposit (investment * p) base to borrow (investment * p) fyToken
        //   (investment * p) fyToken + (investment * (1 - p)) base = investment
        //   (investment * p) / ((investment * p) + (investment * (1 - p))) = p
        //   (investment * (1 - p)) / ((investment * p) + (investment * (1 - p))) = 1 - p

        uint256 baseBalance = base.balanceOf(address(this));
        require(baseBalance > 0, "No funds to start with");

        // The Pool mints based on cached values, not actual ones. Consider bundling a `pool.sync`
        // call if they differ. A griefing attack exists by donating one fyToken wei to the pool
        // before `startPool`, solved the same way.
        uint256 baseInPool = base.balanceOf(address(pool_));
        uint256 fyTokenInPool = fyToken_.balanceOf(address(pool_));

        uint256 baseToPool = (baseBalance * baseInPool).divUp(baseInPool + fyTokenInPool);  // Rounds up
        uint256 fyTokenToPool = baseBalance - baseToPool;        // fyTokenToPool is rounded down

        // Mint fyToken with underlying
        base.safeTransfer(baseJoin, fyTokenToPool);
        fyToken.mintWithUnderlying(address(pool_), fyTokenToPool);

        // Mint LP tokens with (investment * p) fyToken and (investment * (1 - p)) base
        base.safeTransfer(address(pool_), baseToPool);
        (,, cached) = pool_.mint(address(this), address(this), minRatio, maxRatio);

        if (_totalSupply == 0) _mint(msg.sender, cached); // Initialize the strategy if needed

        invariants[address(pool_)] = pool_.invariant();   // Cache the invariant to help the frontend calculate profits
        emit PoolStarted(address(pool_));
    }

    /// @dev Divest out of a pool once it has matured
    function endPool()
        external
        afterMaturity
    {
        // Caching
        IPool pool_ = pool;
        IFYToken fyToken_ = fyToken;

        uint256 toDivest = pool_.balanceOf(address(this));
        
        // Burn lpTokens
        IERC20(address(pool_)).safeTransfer(address(pool_), toDivest);
        (,, uint256 fyTokenDivested) = pool_.burn(address(this), address(this), 0, type(uint256).max); // We don't care about slippage, because the strategy holds to maturity
        
        // Redeem any fyToken
        IERC20(address(fyToken_)).safeTransfer(address(fyToken_), fyTokenDivested);
        fyToken_.redeem(address(this), fyTokenDivested);

        emit PoolEnded(address(pool_));

        // Clear up
        delete pool;
        delete fyToken;
        delete seriesId;
        delete cached;
    }

    /// @dev Mint strategy tokens.
    /// @notice The lp tokens that the user contributes need to have been transferred previously, using a batchable router.
    function mint(address to)
        external
        poolSelected
        returns (uint256 minted)
    {
        // minted = supply * value(deposit) / value(strategy)
        uint256 cached_ = cached;
        uint256 deposit = pool.balanceOf(address(this)) - cached_;
        minted = _totalSupply * deposit / cached_;
        cached = cached_ + deposit;

        _mint(to, minted);
    }

    /// @dev Burn strategy tokens to withdraw lp tokens. The lp tokens obtained won't be of the same pool that the investor deposited,
    /// if the strategy has swapped to another pool.
    /// @notice The strategy tokens that the user burns need to have been transferred previously, using a batchable router.
    function burn(address to)
        external
        poolSelected
        returns (uint256 withdrawal)
    {
        // strategy * burnt/supply = withdrawal
        uint256 cached_ = cached;
        uint256 burnt = _balanceOf[address(this)];
        withdrawal = cached_ * burnt / _totalSupply;
        cached = cached_ - withdrawal;

        _burn(address(this), burnt);
        IERC20(address(pool)).safeTransfer(to, withdrawal);
    }

    /// @dev Burn strategy tokens to withdraw base tokens. It can be called only when a pool is not selected.
    /// @notice The strategy tokens that the user burns need to have been transferred previously, using a batchable router.
    function burnForBase(address to)
        external
        poolNotSelected
        returns (uint256 withdrawal)
    {
        // strategy * burnt/supply = withdrawal
        uint256 burnt = _balanceOf[address(this)];
        withdrawal = base.balanceOf(address(this)) * burnt / _totalSupply;

        _burn(address(this), burnt);
        base.safeTransfer(to, withdrawal);
    }
}