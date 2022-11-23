// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SeasideClubXNextBlockExpoToken is ERC721, Pausable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public constant supply = 500;

    string public baseUri = "https://storage.googleapis.com/seaside-club-x-next-block-expo-token/";

    constructor() ERC721("SeasideClubXNextBlockExpoToken", "SCNBE") {
        _tokenIdCounter.increment();
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint() public {
        require(_tokenIdCounter.current() <= supply, "SeasideClubXNextBlockExpo: supply limit exceeded");
        require(this.balanceOf(_msgSender()) < 1, "SeasideClubXNextBlockExpo: mint limit exceeded");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
    }

    function ownerMint(address to) public onlyOwner {
        require(_tokenIdCounter.current() <= supply, "SeasideClubXNextBlockExpo: supply limit exceeded");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}