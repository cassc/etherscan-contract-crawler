// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract Fragments is ERC1155, Ownable, Pausable, ERC1155Supply, ERC1155Burnable {
    uint256 public maxMintAmount = 10;
    string public name = "The Everlasting Memory Fragments";
    bool public passActive = false;
    string public symbol = "FRG";
    
    constructor() ERC1155(""){}
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function setMaxMint(uint256 _newmaxmint) external onlyOwner {
        maxMintAmount = _newmaxmint;
    }

    function makeNft(uint256 _id) external onlyOwner {
        uint256 nftbalance = balanceOf(msg.sender, _id);
        require(nftbalance < maxMintAmount, "You have exceeding number of mints");
        _mint(msg.sender, _id, maxMintAmount, "");
    }

     function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}