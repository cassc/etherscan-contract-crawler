// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/// @custom:security-contact [email protected]
contract TheBakeryGenesis is DefaultOperatorFilterer, ERC721Royalty, Ownable {


    // DEV NOTES
    // - We do not use ERC721A because we will not have many instances of minting multiple to same wallet
    // - No need to use safeMint because it's extra gas for little benefit
    // - Seems like no one is using OpenSea's contractURI standard

    // - Don't use ERC721Enumerable because it increases gas cost for little benefit
    // - Manually set totalSupply() instead of ERC721Enumerable's implementation
    //   This BREAKS reducing collection size or supply count going down when tokens are burned

    // - `airdrop` is only way to mint. No public mint
    // - Each airdrop call is about 70,000 gas = ~$3 at 26 Gwei + $1,650 ETH

    // - Implements ERC-2981 using ERC721Royalty

    // - Implements OpenSea's Operator Filter


    constructor() ERC721("The Bakery Genesis", "BAKER") {
        // diamondtreasury.eth, 6.9%
        _setDefaultRoyalty(0xf745618062215C135bd3c5E7C0a2185461B6E4d5, 690);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://cdn.thebakery.gg/mainnet-bakers/";
    }

    function totalSupply() public pure returns (uint256) {
        return 1111;
    }

    function airdrop(address to, uint256 newTokenId) public onlyOwner {
        require(newTokenId > 0, "Token ID must be > 0");
        require(newTokenId <= totalSupply(), "Token ID exceeds max supply");
        _mint(to, newTokenId);
    }

    function bulkAirdrop(address[] calldata tos, uint256[] calldata newTokenIds) public onlyOwner {
        require(tos.length == newTokenIds.length);
        for (uint i = 0; i < tos.length; i++) {
            airdrop(tos[i], newTokenIds[i]);
        }
    }

    // OpenSea OperatorFilterer overrides
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