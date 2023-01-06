// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FlashNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    constructor() ERC721("Flashstake NFT", "FLASHNFT") {}

    function contractURI() public pure returns (string memory) {
        return "https://nft.flashstake.io/metadata";
    }

    function _baseURI() internal pure virtual override returns (string memory) {
        return "https://nft.flashstake.io/";
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    // Only the FlashV3 protocol (owner) can burn
    function burn(uint256 _tokenId) public onlyOwner returns (bool) {
        _burn(_tokenId);
        return true;
    }

    // Only the FlashV3 protocol (owner) can mint
    function mint(address _recipientAddress) public onlyOwner returns (uint256) {
        tokenIds.increment();
        _mint(_recipientAddress, tokenIds.current());

        return tokenIds.current();
    }

    function totalSupply() public view returns (uint256) {
        return tokenIds.current();
    }
}