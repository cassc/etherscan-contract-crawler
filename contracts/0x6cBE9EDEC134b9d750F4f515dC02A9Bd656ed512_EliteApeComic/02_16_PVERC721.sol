// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

contract PVERC721 is ERC721Enumerable, ERC721Burnable, Ownable {

    string uri;

    constructor(string memory _name, string memory _symbol, string memory _uri) ERC721(_name, _symbol) {
        uri = _uri;
    }

    function _mintMany(address _account, uint256 _amount) internal {
        for(uint256 i; i < _amount;) {
            _mint(_account, totalSupply() + 1);  

            unchecked {i++;}    
        }    
    }   

    function setURI(string memory _uri) public onlyOwner {
        uri = _uri;    
    }           

    function _baseURI() internal view override returns (string memory) {
        return uri;
    }            

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }   

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }   
}