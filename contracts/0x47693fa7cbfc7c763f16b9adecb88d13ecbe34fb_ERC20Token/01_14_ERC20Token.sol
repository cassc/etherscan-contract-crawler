// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

/**
 * @dev ERC20 token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a pauser role that allows to stop all token transfers
 *
 * The account that deploys the contract will be granted pauser
 * roles, as well as the default admin role, which will let it grant pauser roles to other accounts.
 */
contract ERC20Token is
  AccessControl,
  ERC20Pausable,
  ERC20PresetFixedSupply
{
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /**
   * @dev Grants `DEFAULT_ADMIN_ROLE` and `PAUSER_ROLE` to the deployer
   * Mints initialSupply tokens to deployer
   */
  constructor(
    string memory name,
    string memory symbol,
    uint256 initialSupply,
    address minter
  ) ERC20PresetFixedSupply(name, symbol, initialSupply, minter) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(PAUSER_ROLE, msg.sender);
  }

  /**
   * @dev Pauses all token transfers.
   * Caller must have the `PAUSER_ROLE`.
   */
  function pause() public virtual {
    require(
      hasRole(PAUSER_ROLE, msg.sender),
      "ERC20Token: must have pauser role to pause"
    );
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   * Caller must have the `PAUSER_ROLE`.
   */
  function unpause() public virtual {
    require(
      hasRole(PAUSER_ROLE, msg.sender),
      "ERC20Token: must have pauser role to unpause"
    );
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