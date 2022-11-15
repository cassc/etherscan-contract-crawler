// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {DefaultOperatorFilterer} from "../opensea/operator-filter-registry-main/src/DefaultOperatorFilterer.sol";

contract ConsideringMushrooms is ERC721, Pausable, Ownable, DefaultOperatorFilterer {

    // ---
    // My Code
    // ---

    string public baseURI;
    string public initialBaseURI = "ipfs://QmVwgVy2dAtw7ePyagcNErTZycnzjFfrCUNSL6p1PAGE6p/";

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    receive() external payable {
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getOwnerAddress() public view returns (address) {
        return owner();
    }

    // ---
    // OpenSea Enforcement Creator Fee
    // ---

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

    // ---
    // OpenZeppelin
    // ---

    constructor() ERC721("ConsideringMushrooms", "CMUS") {
        // mint initial set
        address __owner = owner();
        for(uint i = 1; i <= 100; i++) {
            _safeMint(__owner,i);
        }

        // set baseURI 
        baseURI = initialBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
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