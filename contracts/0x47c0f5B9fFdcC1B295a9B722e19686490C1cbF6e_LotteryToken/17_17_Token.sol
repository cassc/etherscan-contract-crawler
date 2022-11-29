// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol';


contract LotteryToken is Ownable, ERC20, ERC20Burnable, ERC20Votes {
  constructor() ERC20('EthernaLotto', 'ELOT') ERC20Permit('EthernaLotto') {
    _mint(msg.sender, 1e9 ether);
  }

  // Disable the delegation mechanism entirely and always assume each user delegates to himself,
  // because we need to use the checkpointing system to calculate the revenue share for each holder.

  function delegates(address account) public pure override returns (address) {
    return account;
  }

  function _delegate(address, address) internal pure override {
    revert('not implemented');
  }

  // The functions below are overrides required by Solidity.

  function _afterTokenTransfer(address from, address to, uint256 amount)
      internal override (ERC20, ERC20Votes)
  {
    super._afterTokenTransfer(from, to, amount);
  }

  function _burn(address account, uint256 amount) internal override (ERC20, ERC20Votes) {
    super._burn(account, amount);
  }

  function _mint(address account, uint256 amount) internal override (ERC20, ERC20Votes) {
    super._mint(account, amount);
  }
}