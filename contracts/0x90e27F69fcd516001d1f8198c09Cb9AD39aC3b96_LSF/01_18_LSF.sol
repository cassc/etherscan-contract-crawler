// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract LSF is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20PermitUpgradeable, AccessControlUpgradeable {

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  function initialize() initializer public {
    __ERC20_init("Longevity.Foundation", "LSF");
    __ERC20Burnable_init();
    __AccessControl_init();
    __ERC20Permit_init("Longevity.Foundation");

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
  }

  function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
    _mint(to, amount);
  }

  function _afterTokenTransfer(address from, address to, uint256 amount)
  internal
  override(ERC20Upgradeable)
  {
    super._afterTokenTransfer(from, to, amount);
  }

  function _mint(address to, uint256 amount)
  internal
  override(ERC20Upgradeable) // override(ERC20, ERC20Votes)
  {
    super._mint(to, amount);
  }

  function _burn(address account, uint256 amount)
  internal
  override(ERC20Upgradeable) // override(ERC20, ERC20Votes)
  {
    super._burn(account, amount);
  }

  function decimals() public view virtual override returns (uint8) {
    return 0;
  }
}