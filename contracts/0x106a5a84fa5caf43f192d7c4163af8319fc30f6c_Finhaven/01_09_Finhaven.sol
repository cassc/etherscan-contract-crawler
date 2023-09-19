// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './extensions/ERC20Burnable.sol';
import './extensions/ERC20Pausable.sol';

contract Finhaven is ERC20Burnable, ERC20Pausable{
	/**
     * Minting FIN Token with a specified initial supply of 1 billion
     * Owner is the deployer address
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) {
        _mint(owner, initialSupply);
    }

    function pause() public virtual onlyOwner{
        _pause();
    }

    function unpause() public virtual onlyOwner{
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