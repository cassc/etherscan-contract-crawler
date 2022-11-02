// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../../interfaces/curve/ICurveDeposit.sol";
import "../../interfaces/curve/ICurveGauge.sol";
import "../../interfaces/curve/ICurveMinter.sol";
import "../../interfaces/sushiswap/IUniswapV2Router.sol";
import "./CurveBaseV2.sol";

/**
 *
 * @notice
 * This is similar to the CurveStable strategy but we have made the base pool and meta pool configurable in the constructor.
 * The strategy allows to deposit a token into the curve base pool, then deposit the lp in the meta pool and stake it in the gauge.
 * Can use any ICurveDepsoitV2 compliant curve base pool and any meta pool.
 */

contract CurveMeta is CurveBaseV2 {
  using SafeERC20 for IERC20;
  using Address for address;

  // the address of the meta pool
  ICurveDepositV2 public immutable metaPool;

  address public immutable metaPoolLpToken;
  address public immutable basePoolLpToken;

  // the index of the want token in the curve base pool
  uint128 public immutable indexOfWantInPool;
  // the number of coins in the base pool
  uint8 internal immutable noPoolCoins;

  constructor(
    address _vault,
    address _proposer,
    address _developer,
    address _keeper,
    address _pool,
    address _basePoolLpToken,
    address _metapool,
    address _metaPoolLpToken,
    uint128 _indexOfWantInPool,
    uint8 _noPoolCoins,
    address _metaPoolGauge
  ) CurveBaseV2(_vault, _proposer, _developer, _keeper, _pool, _metaPoolGauge) {
    require(_metapool != address(0), "!metaPool");
    require(_basePoolLpToken != address(0), "!token");
    require(_metaPoolLpToken != address(0), "!token");
    require(_noPoolCoins >= 2 && _noPoolCoins <= 4, "!poolToken");
    require(_indexOfWantInPool < _noPoolCoins, "!wantIndex");
    indexOfWantInPool = _indexOfWantInPool;
    metaPoolLpToken = _metaPoolLpToken;
    basePoolLpToken = _basePoolLpToken;
    noPoolCoins = _noPoolCoins;
    metaPool = ICurveDepositV2(_metapool);
    _approveCurveExtra();
  }

  function name() external view virtual override returns (string memory) {
    return string("CurveMeta");
  }

  function _getWantTokenIndex() internal view override returns (uint256) {
    return uint256(indexOfWantInPool);
  }

  function _balanceOfPool() internal view virtual override returns (uint256) {
    uint256 lpTokens = curveGauge.balanceOf(address(this));
    if (lpTokens > 0) {
      return _quoteWantInMetapoolLp(lpTokens);
    }
    return 0;
  }

  /// @dev The input is the LP token of the meta pool. To get the value of the original liquidity in the base pool,
  ///  we need to use `calc_withdraw_one_coin` from meta pool and base pool to see how much `want` we will get if we withdraw, without actually doing the withdraw.
  function _quoteWantInMetapoolLp(uint256 _metaPoolLpTokenAmount) public view returns (uint256) {
    uint256 metaPoolTokens = metaPool.calc_withdraw_one_coin(_metaPoolLpTokenAmount, 1);
    return curvePool.calc_withdraw_one_coin(metaPoolTokens, int128(indexOfWantInPool));
  }

  function _approveCurveExtra() internal virtual {
    want.safeApprove(address(curvePool), type(uint256).max);
    IERC20(basePoolLpToken).safeApprove(address(metaPool), type(uint256).max);
  }

  function _addLiquidityToCurvePool() internal virtual override {
    // depsoit to the base pool
    uint256 _wantBalance = _balanceOfWant();
    if (_wantBalance > 0) {
      _depositToCurvePool(_wantBalance, noPoolCoins, indexOfWantInPool);
    }

    // deposit to the meta pool
    uint256 basePoolTokens = IERC20(basePoolLpToken).balanceOf(address(this));
    if (basePoolTokens > 0) {
      // for meta pools the base pool will always be second in the deposit array
      metaPool.add_liquidity([uint256(0), basePoolTokens], 0);
    }
  }

  function _depositLPTokens() internal virtual override {
    uint256 metaPoolLpTokens = IERC20(metaPoolLpToken).balanceOf(address(this));
    if (metaPoolLpTokens > 0) {
      curveGauge.deposit(metaPoolLpTokens);
    }
  }

  /// @dev The `_amount` is in want token, so we need to convert that to basePool tokens first then to metaPool tokens
  ///  We use the `calc_token_amount` to calculate how many LP tokens we will get with the `_amount` of want tokens without actually doing the withdraw.
  ///  Then we add a bit more (2%) for slippage.
  function _withdrawSome(uint256 _amount) internal override returns (uint256) {
    uint256 requiredBasePoollLpTokens = super._calculateLpTokenForWant(_amount);
    uint256 requiredMetaPoollLpTokens = (metaPool.calc_token_amount([0, requiredBasePoollLpTokens], true) * 10200) /
      10000; // adding 2% for fees
    uint256 liquidated = _removeLiquidity(requiredMetaPoollLpTokens);
    return liquidated;
  }

  /// @dev Remove the liquidity by the metaPool token amount
  /// @param _metaPoolTokens The amount of metaPool token (not want or basePool token)
  function _removeLiquidity(uint256 _metaPoolTokens) internal override returns (uint256) {
    uint256 _before = _balanceOfWant();
    uint256 lpBalance = _getLpTokenBalance();
    // need to make sure we don't withdraw more than what we have
    uint256 withdrawAmount = Math.min(lpBalance, _metaPoolTokens);
    // withdraw this amount of lp tokens first
    _removeLpToken(withdrawAmount);
    // then remove the liqudity from the meta pool, will get base pool lp tokens back
    uint256 metaPoolTokens = IERC20(metaPoolLpToken).balanceOf(address(this));
    metaPool.remove_liquidity_one_coin(metaPoolTokens, 1, uint256(0));
    // Remove from the base pool we will get want tokens back
    uint256 curvePoolTokens = IERC20(basePoolLpToken).balanceOf(address(this));
    curvePool.remove_liquidity_one_coin(curvePoolTokens, int128(indexOfWantInPool), 0);
    return _balanceOfWant() - _before;
  }

  function _getCoinsCount() internal view virtual override returns (uint256) {
    return noPoolCoins;
  }

  function _balanceOfPoolInputToken() internal view virtual override returns (uint256) {
    return _balanceOfWant();
  }
}