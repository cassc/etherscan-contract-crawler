// SPDX-License-Identifier: MIT

/**
We fight inflation with $CPI and memes, join the movement #cpi #letitburn
Twitter: @cpi_coin
*/
pragma solidity ^0.8.18;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/security/Pausable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract CPICoin is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("CPICoin", "CPI") {
        _mint(msg.sender, 30000000000 * 10 ** decimals());
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
}