// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "../AladdinCompounderWithStrategy.sol";

contract AladdinETH is AladdinCompounderWithStrategy {
  /// @dev The address of underlying token.
  address private underlying;

  function initialize(
    address _zap,
    address _underlying,
    address _strategy,
    string memory _name,
    string memory _symbol
  ) external initializer {
    AladdinCompounderWithStrategy._initialize(_zap, _strategy, _name, _symbol);

    underlying = _underlying;
  }

  /********************************** View Functions **********************************/

  /// @inheritdoc IAladdinCompounder
  function asset() public view override returns (address) {
    return underlying;
  }

  /// @inheritdoc AladdinCompounderWithStrategy
  function _intermediate() internal pure override returns (address) {
    return address(0);
  }
}