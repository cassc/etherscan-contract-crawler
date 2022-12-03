// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract TheSevensDerivative is DefaultOperatorFilterer, ERC721, Ownable {
    event BaseURIChanged(string newBaseURI);

    uint256 public nextTokenId = 1;

    string public baseURI = "https://outkast.world/sevens/metadata/derivative/";

    constructor() ERC721("The Sevens Derivative Collection", "SEVENS-DC") {}

    function setBaseURI(string calldata newbaseURI) external onlyOwner {
        baseURI = newbaseURI;
        emit BaseURIChanged(newbaseURI);
    }

    function mintTokens(address recipient, uint256 count) external onlyOwner {
        require(recipient != address(0), "TheSevensDC: zero address");

        // Gas optimization
        uint256 _nextTokenId = nextTokenId;

        require(count > 0, "TheSevensDC: invalid count");

        for (uint256 i = 0; i < count; i++) {
            _safeMint(recipient, _nextTokenId + i);
        }

        nextTokenId += count;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Opensea rules must be followed to the derivative creator can earn its fee's

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}