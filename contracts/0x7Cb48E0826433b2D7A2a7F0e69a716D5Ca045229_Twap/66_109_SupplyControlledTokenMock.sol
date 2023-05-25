// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

import "../interfaces/ISupplyControlledERC20.sol";

import "hardhat/console.sol";

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
// ISupplyControlledERC20,
contract SupplyControlledTokenMock is AccessControl, ERC20Burnable {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  /**
   * @dev Grants `DEFAULT_ADMIN_ROLE` to the
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
    _setupRole(MINTER_ROLE, _admin);

    _setupDecimals(_decimals);
  }

  /**
   * @dev Creates `amount` new tokens for `to`.
   *
   * See {ERC20-_mint}.
   *
   */
  function mint(address to, uint256 amount) external {
    require(hasRole(MINTER_ROLE, _msgSender()), "SCTokenMock/MinterRole");
    _mint(to, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20) {
    // console.log(symbol(), from, "->", to);
    // console.log(symbol(), ">", amount);
    super._beforeTokenTransfer(from, to, amount);
  }
}