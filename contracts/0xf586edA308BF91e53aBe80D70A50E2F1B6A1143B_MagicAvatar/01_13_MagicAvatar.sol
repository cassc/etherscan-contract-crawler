// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MagicAvatar is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 public mintPrice = 5000000000000000; // price to mint a new token 0.005 eth

    constructor() ERC721("MagicAvatar", "MgcAvtr") {}

    /**
     * Allows anyone to mint a new token by paying a fee specified by the mintPrice variable
     * @param uri - the URI of the new token
     */
    function mintForFee(string memory uri) public payable {
        require(msg.value == mintPrice, "Incorrect fee");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /**
     * Allows the owner of a token to set its URI
     * @param tokenId - the ID of the token
     * @param uri - the URI to set for the token
     */
    function setTokenURI(uint256 tokenId, string memory uri) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "Sender is not the owner of the token"
        );
        _setTokenURI(tokenId, uri);
    }

    /**
     * Allows the owner of the contract to change the mintPrice variable
     * @param newFee - the new fee for minting a token
     */
    function setNewFee(uint256 newFee) public onlyOwner {
        mintPrice = newFee;
    }

    /**
     * Allows the owner of the contract to mint a new token and set its URI
     * @param to - the address to mint the new token to
     * @param uri - the URI to set for the new token
     */
    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /**
     * Allows the owner of the contract to withdraw any ether stored in the contract
     */
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Insufficient contract balance");
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * Allows to burn a token, it's an internal function
     * @param tokenId - the ID of the token to burn
     */
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    /**
     * Allows to view URI of a token
     * @param tokenId - the ID of the token
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}