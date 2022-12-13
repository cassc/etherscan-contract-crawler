// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC721.sol";
import "ERC721URIStorage.sol";
import "Ownable.sol";
import {DefaultOperatorFilterer} from "DefaultOperatorFilterer.sol";


/// @custom:security-contact [email protected]
contract ExtinctSounds is ERC721, ERC721URIStorage, DefaultOperatorFilterer, Ownable {

    uint256 public tokenCounter;
    bool public initialized = false;

    event NFTMinted(address _to, string _tokenMetadata, uint256 _tokenId);

    constructor() ERC721("ExtinctSounds", "EXS") {
        tokenCounter = 0;
        initialized = true;
    }

    function safeMint(string memory uri) public {
        uint256 tokenId = tokenCounter;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        // approve(msg.sender, tokenId);
        tokenCounter = tokenCounter + 1;
        emit NFTMinted(msg.sender, uri, tokenId);

    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function totalMints() public view returns (uint256) {
        return tokenCounter;
    }

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