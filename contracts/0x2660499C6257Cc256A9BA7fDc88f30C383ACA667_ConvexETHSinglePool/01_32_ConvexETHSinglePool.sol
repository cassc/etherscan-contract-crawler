// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "../curvev2/CurveETHSinglePool.sol";
import "../ConvexBase.sol";

contract ConvexETHSinglePool is CurveETHSinglePool, ConvexBase {
  using SafeERC20 for IERC20;
  address public LDO;

  constructor(
    address _vault,
    address _proposer,
    address _developer,
    address _keeper,
    address _pool,
    address _gauge,
    uint8 _inputTokenIndex,
    uint256 _convexPoolId,
    address _convexBooster,
    address _ldoAddress
  )
    CurveETHSinglePool(_vault, _proposer, _developer, _keeper, _pool, _gauge, _inputTokenIndex)
    ConvexBase(_convexPoolId, _convexBooster)
  {
    LDO = _ldoAddress;
    _approveLdo();
  }

  function name() external pure override returns (string memory) {
    return "ConvexETHSinglePool";
  }

  function _approveDex() internal virtual override {
    super._approveDex();
    _approveDexExtra(dex);
  }

  function _approveLdo() internal virtual {
    IERC20(LDO).safeApprove(dex, type(uint256).max);
  }

  function _balanceOfRewards() internal view virtual override returns (uint256) {
    return _convexRewardsValue(_getCurveTokenAddress(), _getQuoteForTokenToWant);
  }

  function _depositLPTokens() internal virtual override {
    _depositToConvex();
  }

  function _claimRewards() internal virtual override {
    _claimConvexRewards(_getCurveTokenAddress(), _swapToWant);
    _swapToWant(LDO, IERC20(LDO).balanceOf(address(this)));
    // swap lido
  }

  function _getLpTokenBalance() internal view virtual override returns (uint256) {
    return _getConvexBalance();
  }

  function _removeLpToken(uint256 _amount) internal virtual override {
    _withdrawFromConvex(_amount);
  }

  // no need to do anything
  function onHarvest() internal virtual override {}
}