// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LangCoin is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("Language Coin", "LangCoin") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
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

    function multiTransfer(address[] memory addrs, uint[] memory amnts) public whenNotPaused {
        require(addrs.length == amnts.length, "input arrays not equal");
		address owner = super._msgSender();
		for (uint i=0; i < addrs.length; i++) {
			super._transfer(owner, addrs[i], amnts[i]);
		}
    }
}