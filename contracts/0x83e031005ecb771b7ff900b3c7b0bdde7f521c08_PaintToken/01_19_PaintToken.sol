// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract PaintToken is ERC20, ERC20Burnable, ERC20Snapshot, AccessControl, Pausable, ERC20Permit {
  bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  constructor() ERC20("PaintToken", "PAINT") ERC20Permit("PaintToken") {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(SNAPSHOT_ROLE, msg.sender);
    _setupRole(PAUSER_ROLE, msg.sender);
    _mint(msg.sender, 1000000000 * 10 ** decimals());
  }

  function snapshot() public {
    require(hasRole(SNAPSHOT_ROLE, msg.sender));
    _snapshot();
  }

  function pause() public {
    require(hasRole(PAUSER_ROLE, msg.sender));
    _pause();
  }

  function unpause() public {
    require(hasRole(PAUSER_ROLE, msg.sender));
    _unpause();
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount)
  internal
  whenNotPaused
  override(ERC20, ERC20Snapshot)
  {
    super._beforeTokenTransfer(from, to, amount);
  }
}