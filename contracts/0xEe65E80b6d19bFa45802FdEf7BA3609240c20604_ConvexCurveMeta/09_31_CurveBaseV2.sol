// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../BaseStrategy.sol";
import "../../interfaces/curve/ICurveGauge.sol";
import "../../interfaces/curve/ICurveMinter.sol";
import "../../interfaces/curve/ICurveRegistry.sol";
import "../../interfaces/curve/ICurveDeposit.sol";
import "../../interfaces/curve/ICurveAddressProvider.sol";
import "../../interfaces/sushiswap/IUniswapV2Router.sol";

/// @dev The base implementation for all Curve strategies. All strategies will add liquidity to a Curve pool (could be a plain or meta pool), and then deposit the LP tokens to the corresponding gauge to earn Curve tokens.
///  When it comes to harvest time, the Curve tokens will be minted and sold, and the profit will be reported and moved back to the vault.
///  The next time when harvest is called again, the profits from previous harvests will be invested again (if they haven't been withdrawn from the vault).
///  The Convex strategies are pretty much the same as the Curve ones, the only different is that the LP tokens are deposited into Convex instead, and it will take rewards from both Curve and Convex.
abstract contract CurveBaseV2 is BaseStrategy {
  using SafeERC20 for IERC20;
  using Address for address;

  // Minter contract address will never change either. See https://curve.readthedocs.io/dao-gauges.html#minter
  address private constant CURVE_MINTER_ADDRESS = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
  address private constant CRV_TOKEN_ADDRESS = 0xD533a949740bb3306d119CC777fa900bA034cd52;
  address private constant SUSHISWAP_ADDRESS = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
  address private constant UNISWAP_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address private constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  // Curve token minter
  // not immutable because needs to be able to override it for tests
  ICurveMinter public curveMinter;
  // Curve pool. Can be either a plain pool, or meta pool, or Curve zap depositor (automatically add liquidity to base pool and then meta pool).
  ICurveDepositV2 public immutable curvePool;
  // The Curve gauge corresponding to the Curve pool
  ICurveGauge public immutable curveGauge;
  // Dex address for token swaps.
  address public dex;
  // Store dex approval status to avoid excessive approvals
  mapping(address => bool) internal dexApprovals;

  /// @param _vault The address of the vault. The underlying token should match the `want` token of the strategy.
  /// @param _proposer The address of the strategy proposer
  /// @param _developer The address of the strategy developer
  /// @param _keeper The address of the keeper of the strategy.
  /// @param _pool The address of the Curve pool
  constructor(
    address _vault,
    address _proposer,
    address _developer,
    address _keeper,
    address _pool,
    address _gauge
  ) BaseStrategy(_vault, _proposer, _developer, _keeper) {
    require(_pool != address(0), "!pool");
    require(_gauge != address(0), "!gauge");
    minReportDelay = 43_200; // 12hr
    maxReportDelay = 259_200; // 72hr
    profitFactor = 1000;
    debtThreshold = 1e24;
    dex = SUSHISWAP_ADDRESS;
    curvePool = ICurveDepositV2(_pool);
    curveGauge = ICurveGauge(_gauge);
    curveMinter = ICurveMinter(CURVE_MINTER_ADDRESS);
    _approveOnInit();
  }

  /// @notice Approves pools/dexes to be spenders of the tokens of this strategy
  function approveAll() external onlyAuthorized {
    _approveBasic();
    _approveDex();
  }

  /// @notice Changes the dex to use when swap tokens
  /// @param _isUniswap If true, uses Uniswap, otherwise uses Sushiswap
  function switchDex(bool _isUniswap) external onlyAuthorized {
    if (_isUniswap) {
      dex = UNISWAP_ADDRESS;
    } else {
      dex = SUSHISWAP_ADDRESS;
    }
    _approveDex();
  }

  /// @notice Returns the total value of assets in want tokens
  /// @dev it should include the current balance of want tokens, the assets that are deployed and value of rewards so far
  function estimatedTotalAssets() public view virtual override returns (uint256) {
    return _balanceOfWant() + _balanceOfPool() + _balanceOfRewards();
  }

  /// @dev Before migration, we will claim all rewards and remove all liquidity.
  function prepareMigration(address) internal override {
    // mint all the CRV tokens
    _claimRewards();
    _removeLiquidity(_getLpTokenBalance());
  }

  // solhint-disable-next-line no-unused-vars
  /// @dev This will perform the actual invest steps.
  ///   For both Curve & Convex, it will add liquidity to Curve pool(s) first, and then deposit the LP tokens to either Curve gauges or Convex booster.
  function adjustPosition(uint256, bool claimRewards) internal virtual override {
    if (emergencyExit) {
      return;
    }
    if (claimRewards) {
      _claimRewards();
    }
    _addLiquidityToCurvePool();
    _depositLPTokens();
  }

  /// @dev This will claim the rewards from either Curve or Convex, swap them to want tokens and calculate the profit/loss.
  function prepareReturn(uint256 _debtOutstanding)
    internal
    virtual
    override
    returns (
      uint256 _profit,
      uint256 _loss,
      uint256 _debtPayment
    )
  {
    uint256 wantBefore = _balanceOfWant();
    _claimRewards();
    uint256 wantNow = _balanceOfWant();
    _profit = wantNow - wantBefore;

    uint256 _total = estimatedTotalAssets();
    uint256 _debt = IVault(vault).strategy(address(this)).totalDebt;

    if (_total < _debt) {
      _loss = _debt - _total;
      _profit = 0;
    }

    if (_debtOutstanding > 0) {
      _withdrawSome(_debtOutstanding);
      _debtPayment = Math.min(_debtOutstanding, _balanceOfWant() - _profit);
    }
  }

  /// @dev Liquidates the positions from either Curve or Convex.
  function liquidatePosition(uint256 _amountNeeded, bool claimRewards)
    internal
    virtual
    override
    returns (uint256 _liquidatedAmount, uint256 _loss)
  {
    if (claimRewards) {
      _claimRewards();
    }
    uint256 _balance = _balanceOfWant();
    if (_balance < _amountNeeded) {
      _liquidatedAmount = _withdrawSome(_amountNeeded - _balance);
      _liquidatedAmount = _liquidatedAmount + _balance;
      if (_amountNeeded > _liquidatedAmount) {
        _loss = _amountNeeded - _liquidatedAmount;
      }
    } else {
      _liquidatedAmount = _amountNeeded;
    }
  }

  function protectedTokens() internal view virtual override returns (address[] memory) {
    address[] memory protected = new address[](2);
    protected[0] = _getCurveTokenAddress();
    protected[1] = curveGauge.lp_token();
    return protected;
  }

  /// @dev Can be used to perform some actions by the strategy, before the rewards are claimed (like call the checkpoint to update user rewards).
  function onHarvest() internal virtual override {
    // make sure the claimable rewards record is up to date
    curveGauge.user_checkpoint(address(this));
  }

  function _approveOnInit() internal virtual {
    _approveBasic();
    _approveDex();
  }

  /// @dev Returns the balance of the `want` token.
  function _balanceOfWant() internal view returns (uint256) {
    return want.balanceOf(address(this));
  }

  /// @dev Returns total liquidity provided to Curve pools.
  ///  Can be overridden if the strategy has a different way to get the value of the pool.
  function _balanceOfPool() internal view virtual returns (uint256) {
    uint256 lpTokenAmount = _getLpTokenBalance();
    if (lpTokenAmount > 0) {
      uint256 outputAmount = curvePool.calc_withdraw_one_coin(lpTokenAmount, _int128(_getWantTokenIndex()));
      return outputAmount;
    }
    return 0;
  }

  /// @dev Returns the estimated value of the unclaimed rewards.
  function _balanceOfRewards() internal view virtual returns (uint256) {
    uint256 totalClaimableCRV = curveGauge.integrate_fraction(address(this));
    uint256 mintedCRV = curveMinter.minted(address(this), address(curveGauge));
    uint256 remainingCRV = totalClaimableCRV - mintedCRV;

    return _getQuoteForTokenToWant(_getCurveTokenAddress(), remainingCRV);
  }

  /// @dev Swaps the `_from` token to the want token using either Uniswap or Sushiswap
  function _swapToWant(address _from, uint256 _fromAmount) internal virtual returns (uint256) {
    if (_fromAmount > 0) {
      address[] memory path;
      if (address(want) == _getWETHTokenAddress()) {
        path = new address[](2);
        path[0] = _from;
        path[1] = address(want);
      } else {
        path = new address[](3);
        path[0] = _from;
        path[1] = address(_getWETHTokenAddress());
        path[2] = address(want);
      }
      /* solhint-disable  not-rely-on-time */
      uint256[] memory amountOut = IUniswapV2Router(dex).swapExactTokensForTokens(
        _fromAmount,
        uint256(0),
        path,
        address(this),
        block.timestamp
      );
      /* solhint-enable */
      return amountOut[path.length - 1];
    }
    return 0;
  }

  function _depositToCurvePool(
    uint256 _amount,
    uint8 _numberOfTokens,
    uint128 _indexOfTokenInPool
  ) internal virtual {
    if (_numberOfTokens == 2) {
      uint256[2] memory params;
      params[_indexOfTokenInPool] = _amount;
      curvePool.add_liquidity(params, 0);
    } else if (_numberOfTokens == 3) {
      uint256[3] memory params;
      params[_indexOfTokenInPool] = _amount;
      curvePool.add_liquidity(params, 0);
    } else {
      uint256[4] memory params;
      params[_indexOfTokenInPool] = _amount;
      curvePool.add_liquidity(params, 0);
    }
  }

  /// @dev Deposits the LP tokens to Curve gauge.
  function _depositLPTokens() internal virtual {
    address poolLPToken = curveGauge.lp_token();
    uint256 balance = IERC20(poolLPToken).balanceOf(address(this));
    if (balance > 0) {
      curveGauge.deposit(balance);
    }
  }

  /// @dev Withdraws the given amount of want tokens from the Curve pools.
  /// @param _amount The amount of *want* tokens (not LP token).
  function _withdrawSome(uint256 _amount) internal virtual returns (uint256) {
    uint256 requiredLPTokenAmount = _calculateLpTokenForWant(_amount);
    // decide how many LP tokens we can actually withdraw
    return _removeLiquidity(requiredLPTokenAmount);
  }

  function _calculateLpTokenForWant(uint256 _wantAmount) internal virtual returns (uint256) {
    uint256 requiredLPTokenAmount;
    // check how many LP tokens we will need for the given want _amount
    // not great, but can't find a better way to define the params dynamically based on the coins count
    if (_getCoinsCount() == 2) {
      uint256[2] memory params;
      params[_getWantTokenIndex()] = _wantAmount;
      requiredLPTokenAmount = (curvePool.calc_token_amount(params, true) * 10200) / 10000; // adding 2% padding
    } else if (_getCoinsCount() == 3) {
      uint256[3] memory params;
      params[_getWantTokenIndex()] = _wantAmount;
      requiredLPTokenAmount = (curvePool.calc_token_amount(params, true) * 10200) / 10000; // adding 2% padding
    } else if (_getCoinsCount() == 4) {
      uint256[4] memory params;
      params[_getWantTokenIndex()] = _wantAmount;
      requiredLPTokenAmount = (curvePool.calc_token_amount(params, true) * 10200) / 10000; // adding 2% padding
    } else {
      revert("Invalid number of LP tokens");
    }
    return requiredLPTokenAmount;
  }

  /// @dev Removes the liquidity by the LP token amount
  /// @param _amount The amount of LP token (not want token)
  function _removeLiquidity(uint256 _amount) internal virtual returns (uint256) {
    uint256 balance = _getLpTokenBalance();
    uint256 withdrawAmount = Math.min(_amount, balance);
    // withdraw this amount of token from the gauge first
    _removeLpToken(withdrawAmount);
    // then remove the liqudity from the pool, will get want token back
    uint256 balanceBefore = _balanceOfPoolInputToken();
    curvePool.remove_liquidity_one_coin(withdrawAmount, _int128(_getWantTokenIndex()), 0);
    uint256 balanceAfter = _balanceOfPoolInputToken();
    return balanceAfter - balanceBefore;
  }

  /// @dev Returns the total amount of Curve LP tokens the strategy has
  function _getLpTokenBalance() internal view virtual returns (uint256) {
    return curveGauge.balanceOf(address(this));
  }

  /// @dev Withdraws the given amount of LP tokens from Curve gauge
  /// @param _amount The amount of LP tokens to withdraw
  function _removeLpToken(uint256 _amount) internal virtual {
    curveGauge.withdraw(_amount);
  }

  /// @dev Claims the curve rewards tokens and swap them to want tokens
  function _claimRewards() internal virtual {
    curveMinter.mint(address(curveGauge));
    uint256 crvBalance = IERC20(_getCurveTokenAddress()).balanceOf(address(this));
    _swapToWant(_getCurveTokenAddress(), crvBalance);
  }

  /// @dev Returns the address of the Curve token. Use a function to allow override in sub contracts to allow for unit testing.
  function _getCurveTokenAddress() internal view virtual returns (address) {
    return CRV_TOKEN_ADDRESS;
  }

  /// @dev Returns the address of the WETH token. Use a function to allow override in sub contracts to allow for unit testing.
  function _getWETHTokenAddress() internal view virtual returns (address) {
    return WETH_ADDRESS;
  }

  /// @dev Gets an estimate value in want token for the given amount of given token using the dex.
  function _getQuoteForTokenToWant(address _from, uint256 _fromAmount) internal view virtual returns (uint256) {
    if (_fromAmount > 0) {
      address[] memory path;
      if (address(want) == _getWETHTokenAddress()) {
        path = new address[](2);
        path[0] = _from;
        path[1] = address(want);
      } else {
        path = new address[](3);
        path[0] = _from;
        path[1] = address(_getWETHTokenAddress());
        path[2] = address(want);
      }
      uint256[] memory amountOut = IUniswapV2Router(dex).getAmountsOut(_fromAmount, path);
      return amountOut[path.length - 1];
    }
    return 0;
  }

  /// @dev Approves Curve pools/gauges/rewards contracts to access the tokens in the strategy
  function _approveBasic() internal virtual {
    IERC20(curveGauge.lp_token()).safeApprove(address(curveGauge), type(uint256).max);
  }

  /// @dev Approves dex to access tokens in the strategy for swaps
  function _approveDex() internal virtual {
    if (!dexApprovals[dex]) {
      dexApprovals[dex] = true;
      IERC20(_getCurveTokenAddress()).safeApprove(dex, type(uint256).max);
    }
  }

  // does not deal with over/under flow
  function _int128(uint256 _val) internal pure returns (int128) {
    return int128(uint128(_val));
  }

  /// @dev This needs to be overridden by the concrete strategyto implement how liquidity will be added to Curve pools
  function _addLiquidityToCurvePool() internal virtual;

  /// @dev Returns the index of the want token for a Curve pool
  function _getWantTokenIndex() internal view virtual returns (uint256);

  /// @dev Returns the total number of coins the Curve pool supports
  function _getCoinsCount() internal view virtual returns (uint256);

  function _balanceOfPoolInputToken() internal view virtual returns (uint256);
}