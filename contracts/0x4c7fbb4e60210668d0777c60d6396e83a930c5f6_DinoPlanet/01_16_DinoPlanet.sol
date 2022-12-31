// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/[email protected]/security/Pausable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/Counters.sol";

contract DinoPlanet is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    uint256 public MINT_PRICE = 0.25 ether;
    uint256 public MAX_SUPPLY = 10000;
    constructor() ERC721("DinoPlanet", "DINO") {
        _tokenIdCounter.increment();
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Balance is zero");
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmcNhj4PmU3Kz2jAWETU1756k4ocC2T1EP2ovbsC8HF3f7/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) public payable {
        require(totalSupply() < MAX_SUPPLY, "Cannot mint anymore tokens");
        require(msg.value >= MINT_PRICE, "Not enough ether sent.");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
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