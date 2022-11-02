// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;
import "../curvev2/CurveMeta.sol";
import "../ConvexBase.sol";

/**
 *
 * @notice
 * Extends the CurveMeta strategy but so we can use any curve base and meta pool. However, we deposit the metapool lp token to convex instead of the curve gauge.
 * Can use any ICurveDepsoitV2 compliant curve base pool and any meta pool.
 */

contract ConvexCurveMeta is CurveMeta, ConvexBase {
  using SafeERC20 for IERC20;
  using Address for address;

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
    address _convexBooster,
    uint256 _poolId
  )
    CurveMeta(
      _vault,
      _proposer,
      _developer,
      _keeper,
      _pool,
      _basePoolLpToken,
      _metapool,
      _metaPoolLpToken,
      _indexOfWantInPool,
      _noPoolCoins,
      address(1) // address(1) for the gauge as we don't use it fot the convex strategy
    )
    ConvexBase(_poolId, _convexBooster)
  {}

  function name() external view virtual override returns (string memory) {
    return string("ConvexCurveMeta");
  }

  function _approveBasic() internal virtual override {}

  function _approveDex() internal virtual override {
    super._approveDex();
    _approveDexExtra(dex);
  }

  function _balanceOfPool() internal view override returns (uint256) {
    uint256 lpTokens = _getConvexBalance();
    if (lpTokens > 0) {
      return _quoteWantInMetapoolLp(lpTokens);
    }
    return 0;
  }

  function _balanceOfRewards() internal view virtual override returns (uint256) {
    return _convexRewardsValue(_getCurveTokenAddress(), _getQuoteForTokenToWant);
  }

  function _depositLPTokens() internal virtual override {
    _depositToConvex();
  }

  function _claimRewards() internal virtual override {
    _claimConvexRewards(_getCurveTokenAddress(), _swapToWant);
  }

  function _getLpTokenBalance() internal view virtual override returns (uint256) {
    return _getConvexBalance();
  }

  function _removeLpToken(uint256 _amount) internal virtual override {
    _withdrawFromConvex(_amount);
  }

  function protectedTokens() internal view virtual override returns (address[] memory) {
    address[] memory protected = new address[](4);
    protected[0] = _getCurveTokenAddress();
    protected[1] = _getConvexTokenAddress();
    protected[2] = lpToken;
    protected[3] = metaPoolLpToken;
    return protected;
  }

  //override this function as it is only used for the curveGage in the parent contract.
  function onHarvest() internal virtual override {}
}