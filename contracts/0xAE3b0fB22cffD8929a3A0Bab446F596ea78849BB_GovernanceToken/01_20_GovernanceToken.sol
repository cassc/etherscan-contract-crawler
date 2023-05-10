// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "../utils/AdminControl.sol";

contract GovernanceToken is ERC20Votes, AdminControl {
  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) ERC20Permit(_name) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  // The functions below are overrides required by Solidity.
  function mint(address _account, uint256 _amount) external onlyAdmin {
    _mint(_account, _amount);
  }

  function burn(address _account, uint256 _amount) external onlyAdmin {
    _burn(_account, _amount);
  }

  function _transfer(
    address,
    address,
    uint256
  ) internal override {
    revert("token is not transferable");
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20Votes) {
    super._afterTokenTransfer(from, to, amount);
  }

  function _mint(address to, uint256 amount) internal override(ERC20Votes) {
    super._mint(to, amount);
  }

  function _burn(address account, uint256 amount) internal override(ERC20Votes) {
    super._burn(account, amount);
  }
}