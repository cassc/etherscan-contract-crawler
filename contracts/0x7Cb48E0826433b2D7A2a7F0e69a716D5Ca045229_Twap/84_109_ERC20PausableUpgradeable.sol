// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * @title {ERC20} Pausable token through the PAUSER_ROLE
 *
 * @dev This contract uses OpenZeppelin {AccessControlUpgradeable} to lock permissioned functions using the different roles.
 */
abstract contract ERC20PausableUpgradeable is
  Initializable,
  PausableUpgradeable,
  AccessControlUpgradeable,
  ERC20Upgradeable
{
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  // solhint-disable-next-line func-name-mixedcase
  function __ERC20Pausable_init_unchained(address pauser) internal initializer {
    _setupRole(PAUSER_ROLE, pauser);
  }

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function pause() external {
    require(
      hasRole(PAUSER_ROLE, _msgSender()),
      "ERC20Pausable/PauserRoleRequired"
    );
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function unpause() external {
    require(
      hasRole(PAUSER_ROLE, _msgSender()),
      "ERC20Pausable/PauserRoleRequired"
    );
    _unpause();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20Upgradeable) {
    super._beforeTokenTransfer(from, to, amount);

    require(!paused(), "ERC20Pausable/Paused");
  }

  uint256[50] private __gap;
}