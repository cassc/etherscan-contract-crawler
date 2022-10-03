// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract ERC20Governance is ERC20, ERC20Permit, ERC20Votes, Ownable {
  uint8 private _decimal;

  constructor(
    address _owner,
    string memory name,
    string memory symbol,
    uint8 decimal,
    uint256 initialSupply
  ) ERC20(name, symbol) ERC20Permit(name) {
    require(_owner != address(0), "ERC20: address is not zero");
    transferOwnership(_owner);

    _decimal = decimal;
    _mint(_owner, initialSupply);
  }

  function decimals() public view virtual override returns (uint8) {
    return _decimal;
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20, ERC20Votes) {
    super._afterTokenTransfer(from, to, amount);
  }

  function _mint(address to, uint256 amount)
    internal
    override(ERC20, ERC20Votes)
  {
    super._mint(to, amount);
  }

  function _burn(address account, uint256 amount)
    internal
    override(ERC20, ERC20Votes)
  {
    super._burn(account, amount);
  }
}