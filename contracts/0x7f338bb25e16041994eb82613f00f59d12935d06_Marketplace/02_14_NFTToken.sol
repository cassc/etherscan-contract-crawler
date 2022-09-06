// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTToken is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    address marketplace; 
    string ipfsGateway;

    constructor() Ownable() ERC721("ScaleUP NFT", "SUN")  {
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return ipfsGateway;
    }

    function setIPFSGateway(string memory gateway) onlyOwner public {
        ipfsGateway = gateway;
    } 

    function setMarketplace(address newMarketplace) onlyOwner public {
        require(newMarketplace != address(0), "The new marketplace address is required");
        marketplace = newMarketplace;
    }

    function mint(address to, string memory tokenURI)
        public returns (uint256)
    {
        require(msg.sender == marketplace, "Only the marketplace can mint new tokens");
        _tokenIdCounter.increment();
    
        uint256 newItemId = _tokenIdCounter.current();
        _mint(to, newItemId);
        _setTokenURI(newItemId, tokenURI);
        return _tokenIdCounter.current();
    }
}