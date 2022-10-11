// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "./AccessPresetPausable.sol";

/**
 * @title A preset contract that enables pausable access control.
 * @author Nori Inc.
 * @notice This preset contract affords an inheriting contract a set of standard functionality that allows role-based
 * access control and pausable functions.
 * @dev This preset contract is used by all ERC20 tokens in this project.
 *
 * ##### Inherits:
 *
 * - [ERC20BurnableUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20Burnable)
 * - [ERC20PermitUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20Permit)
 * - [MulticallUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#Multicall)
 * - [AccessPresetPausable](../docs/AccessPresetPausable.md)
 */
abstract contract ERC20Preset is
  ERC20BurnableUpgradeable,
  ERC20PermitUpgradeable,
  MulticallUpgradeable,
  AccessPresetPausable
{
  /**
   * @notice Initializes the contract.
   * @dev Grants the `DEFAULT_ADMIN_ROLE` role and `PAUSER_ROLE` role to the initializer.
   */
  function __ERC20Preset_init_unchained() internal onlyInitializing {
    // solhint-disable-previous-line func-name-mixedcase
    _grantRole({role: DEFAULT_ADMIN_ROLE, account: _msgSender()});
    _grantRole({role: PAUSER_ROLE, account: _msgSender()});
  }

  /**
   * @notice A hook that is called before a token transfer occurs.
   * @dev Follows the rules of hooks defined [here](
   * https://docs.openzeppelin.com/contracts/4.x/extending-contracts#rules_of_hooks).
   *
   * ##### Requirements:
   *
   * - The contract must not be paused.
   * @param from The address of the sender.
   * @param to The address of the recipient.
   * @param amount The amount of tokens to transfer.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override whenNotPaused {
    super._beforeTokenTransfer({from: from, to: to, amount: amount});
  }

  /**
   * @notice See ERC20-approve for more details [here](
   * https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20-approve-address-uint256-).
   * @dev This override applies the `whenNotPaused` to the `approve`, `increaseAllowance`, `decreaseAllowance`,
   * and `_spendAllowance` (used by `transferFrom`) functions.
   *
   * ##### Requirements:
   *
   * - The contract must not be paused.
   * - Accounts cannot have allowance issued by their operators.
   * - If `value` is the maximum `uint256`, the allowance does not update `transferFrom`. This is semantically
   * equivalent to an infinite approval.
   * - `owner` cannot be the zero address.
   * - The `spender` cannot be the zero address.
   * @param owner The owner of the tokens.
   * @param spender The address of the designated spender. This address is allowed to spend the tokens on behalf of the
   * `owner` up to the `amount` value.
   * @param amount The amount of tokens to afford the `spender`.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual override whenNotPaused {
    return super._approve({owner: owner, spender: spender, amount: amount});
  }
}