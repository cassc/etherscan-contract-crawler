// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./utils/NFTPausable.sol";

contract BWBNFT is ERC721, ERC721URIStorage, Ownable , NFTPausable{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Busan Blockchain Week_ Edition 01 ", "BWB") {
	}

    function safeMint(address to, string memory uri) public returns(uint) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer (address _from , address _to , uint256 _tokenid) internal override {
        require (!Paused(address(this),_tokenid) , "nft is paused!");

        super._beforeTokenTransfer (_from , _to , _tokenid);
    }

    function nftPause (address _nftaddress , uint256 _tokenid) public onlyOwner {
        _nftPause(_nftaddress , _tokenid);
    }

    function nftUnPause (address _nftaddress , uint256 _tokenid) public onlyOwner {
        _nftUnPause(_nftaddress , _tokenid);
    }

}