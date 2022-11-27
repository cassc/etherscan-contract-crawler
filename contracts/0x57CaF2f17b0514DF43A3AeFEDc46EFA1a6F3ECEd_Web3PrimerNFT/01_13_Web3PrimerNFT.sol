// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Web3PrimerNFT is ERC721Enumerable, Ownable {
    mapping(address => bool) public inWhitelist;
    uint256 public lastTokenId;

    constructor() ERC721("Web3Primer", "W3P") {}

    function addToWhitelist(address[] memory members) external onlyOwner {
        for (uint256 i = 0; i < members.length; i++) {
            inWhitelist[members[i]] = true;
        }
    }

    function removeFromWhitelist(address[] memory members) external onlyOwner {
        for (uint256 i = 0; i < members.length; i++) {
            inWhitelist[members[i]] = false;
        }
    }

    function mint() external returns (uint256) {
        require(inWhitelist[msg.sender], "not in whitelist");
        inWhitelist[msg.sender] = false;
        uint256 tokenId = lastTokenId;
        _safeMint(msg.sender, tokenId);
        lastTokenId += 1;
        return tokenId;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        revert("Transfer Forbidden");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        revert("Transfer Forbidden");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        revert("Transfer Forbidden");
    }
}