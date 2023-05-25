// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * This has an open mint functionality
 */
contract TokenMock is Context, AccessControl, ERC20Burnable, ERC20Pausable {
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /**
   * @dev Grants `DEFAULT_ADMIN_ROLE`, and `PAUSER_ROLE` to the
   * account that deploys the contract.
   *
   * See {ERC20-constructor}.
   */
  constructor(
    address _admin,
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) ERC20(_name, _symbol) {
    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    _setupRole(PAUSER_ROLE, _admin);

    _setupDecimals(_decimals);
  }

  /**
   * @dev Creates `amount` new tokens for `to`.
   *
   * See {ERC20-_mint}.
   *
   */
  function mint(address to, uint256 amount) external virtual {
    _mint(to, amount);
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
  function pause() external virtual {
    require(hasRole(PAUSER_ROLE, _msgSender()), "TokenMock/PauserRole");
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
  function unpause() external virtual {
    require(hasRole(PAUSER_ROLE, _msgSender()), "TokenMock/PauserRole");
    _unpause();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20, ERC20Pausable) {
    super._beforeTokenTransfer(from, to, amount);
  }
}