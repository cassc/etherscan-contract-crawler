// SPDX-License-Identifier: MIT

//   _  __             _                    
//  | |/ /__ _ ___ ___(_) ___  _ __   __ _  
//  | ' // _` / __/ __| |/ _ \| '_ \ / _` | 
//  | . \ (_| \__ \__ \ | (_) | | | | (_| | 
//  |_|\_\__,_|___/___/_|\___/|_| |_|\__,_| 



pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';


contract KassionaChips is Ownable, ERC1155Pausable, ERC1155Burnable {
    using Strings for uint256;

    address public admin; 

    uint256 price = 2e15;

    constructor() ERC1155("CHIP") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, 1, amount, new bytes(0));
    }

    function buy(uint256 amount) external payable {
        require(msg.value>= amount*price,"eth not enough");
        _mint(msg.sender, 1, amount, new bytes(0));
    }

    function setPrice(uint256 price_) external onlyOwner{
        price = price_;
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

   
    function setURI(string memory newURI) public onlyOwner {
        _setURI(newURI);    
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory baseURI = super.uri(0);
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function isApprovedForAll(address account, address operator) public override view returns (bool) {
        if (operator == admin) {
            return true;
        }

        return super.isApprovedForAll(account, operator);
    }

    function setAdmin(address admin_) external onlyOwner {
        admin = admin_;
    }

    function withdraw() external onlyOwner{
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}