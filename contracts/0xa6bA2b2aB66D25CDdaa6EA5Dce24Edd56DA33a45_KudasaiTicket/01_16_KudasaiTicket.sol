// SPDX-License-Identifier: MIT
//  ___   _  __   __  ______   _______  _______  _______  ___  
// |   | | ||  | |  ||      | |   _   ||       ||   _   ||   | 
// |   |_| ||  | |  ||  _    ||  |_|  ||  _____||  |_|  ||   | 
// |      _||  |_|  || | |   ||       || |_____ |       ||   | 
// |     |_ |       || |_|   ||       ||_____  ||       ||   | 
// |    _  ||       ||       ||   _   | _____| ||   _   ||   | 
// |___| |_||_______||______| |__| |__||_______||__| |__||___| 

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract KudasaiTicket is ERC721Enumerable, ERC721Royalty, Ownable {
    uint256 private constant _tokenMaxSupply = 2000;
    string private _baseTokenUri;
    event Mint(uint256 id);

    constructor(string memory baseTokenUri_) ERC721("KudasaiTicket", "KT") {
        _baseTokenUri = baseTokenUri_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseUri(string memory newUri) external onlyOwner {
        _baseTokenUri = newUri;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        return _baseTokenUri;
    }

    function setRoyaltyInfo(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function ownerMint(address _to, uint256 _quantity) public onlyOwner {
        require(totalSupply() + _quantity <= _tokenMaxSupply, "No more");
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 mintId = totalSupply();
            _safeMint(_to, mintId);
            emit Mint(mintId);
        }
    }
}