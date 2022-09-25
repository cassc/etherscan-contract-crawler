// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/Counters.sol';

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

import "@openzeppelin/contracts/access/Ownable.sol";

contract EternalNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    constructor() ERC721('EternalNFT', 'ENT') {}

    Counters.Counter private _tokenIds;

    uint256 listingPrice = 0.0075 ether;

    function createToken(string memory tokenURI)
        public
        payable
        returns (uint256)
    {
        require(
            msg.value == listingPrice,
            'Call value must be equal to listing price'
        );

        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        // createMarketItem(newTokenId, price);

        payable(owner()).transfer(msg.value);

        return newTokenId;
    }

    // Admin only functions
    function updateListingPrice(uint256 _listingPrice) public onlyOwner {
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }
}