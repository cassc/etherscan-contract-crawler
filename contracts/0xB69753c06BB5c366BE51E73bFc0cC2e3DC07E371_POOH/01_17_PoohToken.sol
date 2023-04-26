// SPDX-License-Identifier: MIT
/*
      ___         ___           ___           ___                                  ___           ___           ___           ___     
     /\  \       /\  \         /\  \         /\  \                                /\  \         /|  |         /\__\         /\  \    
    /::\  \     /::\  \       /::\  \        \:\  \                  ___         /::\  \       |:|  |        /:/ _/_        \:\  \   
   /:/\:\__\   /:/\:\  \     /:/\:\  \        \:\  \                /\__\       /:/\:\  \      |:|  |       /:/ /\__\        \:\  \  
  /:/ /:/  /  /:/  \:\  \   /:/  \:\  \   ___ /::\  \              /:/  /      /:/  \:\  \   __|:|  |      /:/ /:/ _/_   _____\:\  \ 
 /:/_/:/  /  /:/__/ \:\__\ /:/__/ \:\__\ /\  /:/\:\__\            /:/__/      /:/__/ \:\__\ /\ |:|__|____ /:/_/:/ /\__\ /::::::::\__\
 \:\/:/  /   \:\  \ /:/  / \:\  \ /:/  / \:\/:/  \/__/           /::\  \      \:\  \ /:/  / \:\/:::::/__/ \:\/:/ /:/  / \:\~~\~~\/__/
  \::/__/     \:\  /:/  /   \:\  /:/  /   \::/__/               /:/\:\  \      \:\  /:/  /   \::/~~/~      \::/_/:/  /   \:\  \      
   \:\  \      \:\/:/  /     \:\/:/  /     \:\  \               \/__\:\  \      \:\/:/  /     \:\~~\        \:\/:/  /     \:\  \     
    \:\__\      \::/  /       \::/  /       \:\__\                   \:\__\      \::/  /       \:\__\        \::/  /       \:\__\    
     \/__/       \/__/         \/__/         \/__/                    \/__/       \/__/         \/__/         \/__/         \/__/    

      Website: https://pooh.money/
      Telegram: https://t.me/poohmoneyHQ
       Twitter: https://twitter.com/poohmoneyHQ




*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract POOH is ERC20, ERC20Burnable, ERC20Permit, ERC20Votes, Ownable {
    constructor() ERC20("POOH", "POOH") ERC20Permit("POOH") {
        _mint(msg.sender, 420690000000000 * 10 ** decimals());
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
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