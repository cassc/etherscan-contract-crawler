// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract TreenvestToken is ERC20, ERC20Burnable, Pausable, AccessControl, ERC20Permit {
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant TRADER_ROLE = keccak256("TRADER_ROLE");
  bytes32 public constant SWAP_ROLE = keccak256("SWAP_ROLE");

  uint256 public constant MAX_SUPPLY = 1_000_000_000_000_000 * 10 ** 18;

  bool private _swap_paused;

  modifier notPaused() {
    if (paused()) {
      require(hasRole(MINTER_ROLE, _msgSender()), "TreenvestToken: paused");
    }
    _;
  }

  modifier swapNotPaused() {
    if (swapPaused()) {
      if (hasRole(SWAP_ROLE, _msgSender())) {
        require(hasRole(TRADER_ROLE, tx.origin), "TreenvestToken: swap paused");
      }
    }
    _;
  }

  constructor() ERC20("Treenvest Token", "TVT") ERC20Permit("Treenvest Token") {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    _grantRole(TRADER_ROLE, msg.sender);

    _mint(msg.sender, 1_000_000_000_000 * 10 ** 18);
  }

  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  function swapPaused() public view returns (bool) {
    return _swap_paused;
  }

  function pauseSwap() public onlyRole(PAUSER_ROLE) {
    _swap_paused = true;
  }

  function unpauseSwap() public onlyRole(PAUSER_ROLE) {
    _swap_paused = false;
  }

  function mintToken(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
    _mint(to, amount);
  }

  function burnToken(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
    _burn(account, amount);
  }

  function batchTransfer(
    address[] memory recipients,
    uint256[] memory amounts
  ) public notPaused {
    require(
      recipients.length == amounts.length,
      "TreenvestToken: recipients and amounts length mismatch"
    );
    for (uint256 i = 0; i < recipients.length; i++) {
      _transfer(_msgSender(), recipients[i], amounts[i]);
    }
  }

  function batchMint(
    address[] memory recipients,
    uint256[] memory amounts
  ) public onlyRole(MINTER_ROLE) {
    require(
      recipients.length == amounts.length,
      "TreenvestToken: recipients and amounts length mismatch"
    );
    for (uint256 i = 0; i < recipients.length; i++) {
      _mint(recipients[i], amounts[i]);
    }
  }

  function batchBurn(
    address[] memory accounts,
    uint256[] memory amounts
  ) public onlyRole(MINTER_ROLE) {
    require(
      accounts.length == amounts.length,
      "TreenvestToken: accounts and amounts length mismatch"
    );
    for (uint256 i = 0; i < accounts.length; i++) {
      _burn(accounts[i], amounts[i]);
    }
  }

  function batchGrantRole(
    bytes32 role,
    address[] memory accounts
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint256 i = 0; i < accounts.length; i++) {
      grantRole(role, accounts[i]);
    }
  }

  function batchRevokeRole(
    bytes32 role,
    address[] memory accounts
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint256 i = 0; i < accounts.length; i++) {
      revokeRole(role, accounts[i]);
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override notPaused swapNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }
}