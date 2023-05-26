// SPDX-License-Identifier: MIT
//Audited and Edited by Haithem SaferICO Telegram: @SFI_admin

pragma solidity 0.8.14;

import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Votes.sol";

contract TokenBot is
    ERC20,
    ERC20Burnable,
    Ownable,
    ERC20Permit,
    ERC20Votes
{
    uint256 public immutable MAX_SUPPLY = 1000000000000000000000000000;
   
    constructor()
        ERC20("TokenBot", "TKB")
        ERC20Permit("TokenBot")
    {}

    function mint(
        address to,
        uint256 amount
    ) public onlyOwner {
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "TokenBot::mint: mint amount exceeds MAX_SUPPLY"
        );
        require(to != address(0) , "can't mint for zero address");
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override(ERC20, ERC20Votes)
    {
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