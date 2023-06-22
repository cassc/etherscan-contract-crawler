// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ClayFriendsSpecials is ERC721, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    
    uint256 private _tokenIdTracker;
    
    string public baseTokenURI;

    bool public publicSaleOpen;

    event CreateItem(uint256 indexed id);
    constructor()
    ERC721("Clay Friends Specials", "CFS") 
    {}

    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker;
    }

    function airdrop(address[] calldata _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mintAnElement(_addresses[i]);
        }
    }

    function ownerMint(uint256 _count) public onlyOwner {
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }
    }

    function _mintAnElement(address _to) private {
        uint id = totalSupply();
        _tokenIdTracker += 1;
        _mint(_to, id);
        emit CreateItem(id);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}