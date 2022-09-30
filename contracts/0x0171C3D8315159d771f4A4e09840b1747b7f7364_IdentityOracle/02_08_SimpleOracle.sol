// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import './BaseOracle.sol';

/**
 * @title A simple implementation of `BaseOracle` that already implements functions to add support
 * @notice Most implementations of `ITokenPriceOracle` will have an internal function that is called in both
 *         `addSupportForPairIfNeeded` and `addOrModifySupportForPair`. This oracle is now making this explicit, and
 *         implementing these two functions. They remain virtual so that they can be overriden if needed.
 */
abstract contract SimpleOracle is BaseOracle {
  ///@inheritdoc ITokenPriceOracle
  function isPairAlreadySupported(address tokenA, address tokenB) public view virtual returns (bool);

  ///@inheritdoc ITokenPriceOracle
  function addOrModifySupportForPair(
    address _tokenA,
    address _tokenB,
    bytes calldata _data
  ) external virtual {
    _addOrModifySupportForPair(_tokenA, _tokenB, _data);
  }

  ///@inheritdoc ITokenPriceOracle
  function addSupportForPairIfNeeded(
    address _tokenA,
    address _tokenB,
    bytes calldata _data
  ) external virtual {
    if (!isPairAlreadySupported(_tokenA, _tokenB)) {
      _addOrModifySupportForPair(_tokenA, _tokenB, _data);
    }
  }

  /**
   * @notice Add or reconfigures the support for a given pair. This function will let the oracle take some actions
   *         to configure the pair, in preparation for future quotes. Can be called many times in order to let the oracle
   *         re-configure for a new context
   * @dev Will revert if pair cannot be supported. tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @param data Custom data that the oracle might need to operate
   */
  function _addOrModifySupportForPair(
    address tokenA,
    address tokenB,
    bytes calldata data
  ) internal virtual;
}