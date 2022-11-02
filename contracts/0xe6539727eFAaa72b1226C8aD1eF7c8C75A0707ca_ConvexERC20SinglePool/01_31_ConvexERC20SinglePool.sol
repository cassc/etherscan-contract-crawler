// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "../curvev2/CurveERC20SinglePool.sol";
import "../ConvexBase.sol";

contract ConvexERC20SinglePool is CurveERC20SinglePool, ConvexBase {
  using SafeERC20 for IERC20;

  constructor(
    address _vault,
    address _proposer,
    address _developer,
    address _keeper,
    address _pool,
    address _gauge,
    uint8 _numberOfPoolTokens,
    uint8 _inputTokenIndex,
    address _inputTokenAddress,
    bool _isZapDepositor,
    uint256 _convexPoolId,
    address _convexBooster
  )
    CurveERC20SinglePool(
      _vault,
      _proposer,
      _developer,
      _keeper,
      _pool,
      _gauge,
      _numberOfPoolTokens,
      _inputTokenIndex,
      _inputTokenAddress,
      _isZapDepositor
    )
    ConvexBase(_convexPoolId, _convexBooster)
  {}

  function name() external view override returns (string memory) {
    return string(abi.encodePacked("ConvexERC20SinglePool_", IERC20Metadata(address(want)).symbol()));
  }

  function _approveDex() internal virtual override {
    super._approveDex();
    _approveDexExtra(dex);
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

  function _balanceOfPoolInputToken() internal view virtual override returns (uint256) {
    return _balanceOfWant();
  }
}