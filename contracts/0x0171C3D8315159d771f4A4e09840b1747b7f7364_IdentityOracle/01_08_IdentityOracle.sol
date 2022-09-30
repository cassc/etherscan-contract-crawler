// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import './base/SimpleOracle.sol';

/// @notice An oracle that works for pairs where both tokens are the same
contract IdentityOracle is SimpleOracle {
  /// @inheritdoc ITokenPriceOracle
  function canSupportPair(address _tokenA, address _tokenB) external pure returns (bool) {
    return _tokenA == _tokenB;
  }

  /// @inheritdoc ITokenPriceOracle
  function isPairAlreadySupported(address _tokenA, address _tokenB) public pure override returns (bool) {
    return _tokenA == _tokenB;
  }

  /// @inheritdoc ITokenPriceOracle
  function quote(
    address _tokenIn,
    uint256 _amountIn,
    address _tokenOut,
    bytes calldata
  ) external pure returns (uint256 _amountOut) {
    if (_tokenIn != _tokenOut) revert PairNotSupportedYet(_tokenIn, _tokenOut);
    return _amountIn;
  }

  function _addOrModifySupportForPair(
    address _tokenA,
    address _tokenB,
    bytes calldata
  ) internal pure override {
    if (_tokenA != _tokenB) revert PairCannotBeSupported(_tokenA, _tokenB);
  }
}