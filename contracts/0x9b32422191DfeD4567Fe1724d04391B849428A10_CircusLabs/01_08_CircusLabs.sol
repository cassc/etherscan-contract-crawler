// SPDX-License-Identifier: MIT
//     ________ ___  ___  ___       ___               ________  ___  ________  ________  ___  ___  ________      
//    |\  _____\\  \|\  \|\  \     |\  \             |\   ____\|\  \|\   __  \|\   ____\|\  \|\  \|\   ____\     
//    \ \  \__/\ \  \\\  \ \  \    \ \  \            \ \  \___|\ \  \ \  \|\  \ \  \___|\ \  \\\  \ \  \___|_    
//     \ \   __\\ \  \\\  \ \  \    \ \  \            \ \  \    \ \  \ \   _  _\ \  \    \ \  \\\  \ \_____  \   
//      \ \  \_| \ \  \\\  \ \  \____\ \  \____        \ \  \____\ \  \ \  \\  \\ \  \____\ \  \\\  \|____|\  \  
//       \ \__\   \ \_______\ \_______\ \_______\       \ \_______\ \__\ \__\\ _\\ \_______\ \_______\____\_\  \ 
//        \|__|    \|_______|\|_______|\|_______|        \|_______|\|__|\|__|\|__|\|_______|\|_______|\_________\
//                                                                                                   \|_________|
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CircusLabs is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor(string memory tokenName, string memory tokenSymbol, address owner) ERC20(tokenName, tokenSymbol) {
        _mint(owner, 1000000000 * 10 ** decimals());
        _transferOwnership(owner);
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