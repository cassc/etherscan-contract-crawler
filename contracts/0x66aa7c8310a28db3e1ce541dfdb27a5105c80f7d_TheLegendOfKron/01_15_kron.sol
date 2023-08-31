// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TheLegendOfKron is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    string _baseUri;
    uint256 TOTAL_SUPPLY = 1440;
    uint MINT_PRICE = 0.1 ether;
    bool MINT_ACTIVE = false;

    Counters.Counter private _tokenIdCounter;

    constructor(string memory _uri) ERC721("KRONICLE", "KRON") {

        _tokenIdCounter._value = 1;
        _baseUri = _uri;
    }


    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _baseUri = _uri;
    }

    function toggleMintActive() public onlyOwner {
        MINT_ACTIVE = !MINT_ACTIVE;
    }

    function buy(address to) public payable {
        require(msg.value >= MINT_PRICE, "Send more ETH"); 
        require(MINT_ACTIVE, "MINT NOT ACTIVE YET"); 
        safeMint(to);
    }

    function safeMintOwner(address to) public onlyOwner {
        safeMint(to);
    }

    function safeMint(address to) internal {

        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= TOTAL_SUPPLY, "Max supply reached");        
        
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function withdraw() public onlyOwner{

        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);

    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}