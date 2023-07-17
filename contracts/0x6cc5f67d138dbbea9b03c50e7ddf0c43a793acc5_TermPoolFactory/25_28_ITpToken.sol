// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol';

interface ITpToken is IERC20MetadataUpgradeable {
  /// @notice Function is used to provide liquidity for TermPool in exchange for tpTokens
  /// @dev Approval for desired amount of currency token should be given in prior
  /// @param currencyAmount Amount of currency token that user want to provide
  function mint(address to, uint256 currencyAmount) external;

  /// @notice Function is used to redeem previously provided liquidity with interest, burning tpTokens
  /// @param currencyAmount Amount of tpTokens to burn
  function burn(address from, uint256 currencyAmount) external;

  error NotTermPool(address sender);
}