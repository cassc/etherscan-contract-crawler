// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library CurrencyTransferLib {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @dev The address interpreted as native token of the chain.
  address public constant NATIVE_TOKEN = 0x0000000000000000000000000000000000000000;

  /// @dev Transfers a given amount of currency.
  function transferCurrency(
    address currency,
    address from,
    address to,
    uint256 amount
  ) internal {
    if (amount == 0) {
      return;
    }

    if (currency == NATIVE_TOKEN) {
      safeTransferNativeToken(to, amount);
    } else {
      safeTransferERC20(currency, from, to, amount);
    }
  }

  /// @dev Transfers `amount` of native token to `to`.
  function safeTransferNativeToken(address to, uint256 value) internal {
    // solhint-disable avoid-low-level-calls
    // slither-disable-next-line low-level-calls
    (bool success, ) = to.call{ value: value }("");
    require(success, "Native token transfer failed");
  }

  /// @dev Transfer `amount` of ERC20 token from `from` to `to`.
  function safeTransferERC20(
    address currency,
    address from,
    address to,
    uint256 amount
  ) internal {
    if (from == to) {
      return;
    }

    if (from == address(this)) {
      IERC20Upgradeable(currency).safeTransfer(to, amount);
    } else {
      IERC20Upgradeable(currency).safeTransferFrom(from, to, amount);
    }
  }
}