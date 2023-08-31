// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract PHFantasyFootball22 is ERC721A, Ownable  {
    uint256 public MAX_SUPPLY = 2;
    string public baseUri = "ipfs://Qmb4TWk8NcVDNUgNVpc95wHs29byBaqLdav43mPdb9n6ts/";

    constructor() ERC721A("PHFantasyFootball22", "PHFF22") {}

    function safeMint(address to) external onlyOwner {
        require (_totalMinted() <= MAX_SUPPLY, "Error: Max supply reached.");
        _safeMint(to, 1);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) pure override internal {
        require(from == address(0) || to == address(0), "Error: Soulbound token cannot be transferred.");
    }

    function _burn(uint256 tokenId, bool approvalCheck) override internal {
        require(ownerOf(tokenId) == msg.sender, "Error: Only owner can burn.");
        _burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setBaseUri(string memory newUri) external onlyOwner {
        baseUri = newUri;
    }

}