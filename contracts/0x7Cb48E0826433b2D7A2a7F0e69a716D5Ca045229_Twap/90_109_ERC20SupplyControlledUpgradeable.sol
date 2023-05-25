// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title {ERC20} Supply Controlled token that allows burning (by all), and minting
 * by MINTER_ROLE
 *
 * @dev This contract uses OpenZeppelin {AccessControlUpgradeable} to lock permissioned functions using the different roles.
 */
abstract contract ERC20SupplyControlledUpgradeable is
  Initializable,
  AccessControlUpgradeable,
  ERC20Upgradeable
{
  using SafeMath for uint256;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  // solhint-disable-next-line func-name-mixedcase
  function __ERC20SupplyControlled_init_unchained(address minter)
    internal
    initializer
  {
    _setupRole(MINTER_ROLE, minter);
  }

  /**
   * @dev Creates `amount` new tokens for `to`.
   *
   * See {ERC20-_mint}.
   *
   * Requirements:
   *
   * - the caller must have the `MINTER_ROLE`.
   */
  function mint(address to, uint256 amount) external virtual {
    require(
      hasRole(MINTER_ROLE, _msgSender()),
      "ERC20SupplyControlled/MinterRole"
    );
    _mint(to, amount);
  }

  /**
   * @dev Destroys `amount` tokens from the caller.
   *
   * See {ERC20-_burn}.
   */
  function burn(uint256 amount) external virtual {
    _burn(_msgSender(), amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, deducting from the caller's
   * allowance.
   *
   * See {ERC20-_burn} and {ERC20-allowance}.
   *
   * Requirements:
   *
   * - the caller must have allowance for `accounts`'s tokens of at least
   * `amount`.
   */
  function burnFrom(address account, uint256 amount) external virtual {
    uint256 decreasedAllowance =
      allowance(account, _msgSender()).sub(
        amount,
        "ERC20SupplyControlled/Overburn"
      );

    _approve(account, _msgSender(), decreasedAllowance);
    _burn(account, amount);
  }

  uint256[50] private __gap;
}