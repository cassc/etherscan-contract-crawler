// SPDX-License-Identifier: MIT

/*

     ___   .___________.  ______   .___  ___. ____    ____  _______ .______          _______. _______ 
    /   \  |           | /  __  \  |   \/   | \   \  /   / |   ____||   _  \        /       ||   ____|
   /  ^  \ `---|  |----`|  |  |  | |  \  /  |  \   \/   /  |  |__   |  |_)  |      |   (----`|  |__   
  /  /_\  \    |  |     |  |  |  | |  |\/|  |   \      /   |   __|  |      /        \   \    |   __|  
 /  _____  \   |  |     |  `--'  | |  |  |  |    \    /    |  |____ |  |\  \----.----)   |   |  |____ 
/__/     \__\  |__|      \______/  |__|  |__|     \__/     |_______|| _| `._____|_______/    |_______|
                                                                                                      

*/


pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract atom_catalyst is ERC1155, Ownable, ERC1155Burnable {
    address[] private holders;
    constructor() ERC1155("") {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

}