// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";
import "ERC721URIStorage.sol";
import "Counters.sol";

contract NFTCollection is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public creator;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        creator = msg.sender;
    }

    event tokenMinted(string tokenURI, address owner);

    function mintTo(string memory tokenURI)
        external
        returns (uint256)
    {
        //require(creator == msg.sender, "Only owner can mint nft on this address.");
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        _tokenIds.increment();
        emit tokenMinted(tokenURI, msg.sender);
        return newItemId;
    }

    function getCurrentId() public returns(uint256) {
        return _tokenIds.current();
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        _burn(tokenId);
    }
}