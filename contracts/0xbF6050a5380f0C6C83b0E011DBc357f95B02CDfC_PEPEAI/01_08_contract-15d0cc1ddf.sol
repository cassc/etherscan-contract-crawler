// SPDX-License-Identifier: MIT
//Welcome to PEPEAI 
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/security/Pausable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract PEPEAI is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("PEPEAI", "PEPEAI") {
        _mint(msg.sender, 420690000000000 * 10 ** decimals());
    }

    function pepeai() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}