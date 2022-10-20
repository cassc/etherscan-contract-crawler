// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @custom:security-contact [email protected]
contract DoersNFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("DoersNFT", "DOER") {}

    function contractURI() public pure returns (string memory) {
        return "ipfs://bafkreidlkuk74h2nhgq7b76awhm43wxwhaxr6srgi475k7kp3c5p4m5lnq";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        return "ipfs://bafkreideevywiumhmur4uognav3mlaczpyulgcypvb2x7nstz2d7rb5n6e";
    }

    function mint(address to) public payable {
        require(msg.value >= 1000000000000000000, "Minting a Doers NFT 1.0 requires 1ETH."); 
        
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < 10, "All Doers NFT 1.0 tokens have already been minted.");

        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
}