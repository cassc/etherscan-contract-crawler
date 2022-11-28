// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import 'erc721a/contracts/ERC721A.sol';
import 'erc721a/contracts/IERC721A.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

contract ERC721Base is ERC721A, ERC2981, DefaultOperatorFilterer {
    string internal _tokenURI;
    uint256 public MAX_SUPPLY;

    constructor(
        string memory tokenURI_,
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        address royaltyReceiver_,
        uint96 royaltyFraction_
    ) ERC721A(name_, symbol_) {
        _tokenURI = tokenURI_;
        MAX_SUPPLY = maxSupply_;
        _setDefaultRoyalty(royaltyReceiver_, royaltyFraction_);
    }

    // Metadata
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenURI;
    }

    function _setTokenURI(string calldata _uri) internal {
        _tokenURI = _uri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory baseURI = _baseURI();
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (bytes(baseURI).length == 0) return '';

        return
            string(abi.encodePacked(baseURI, '/', _toString(tokenId), '.json'));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    bool filter = true;

    // Operator Filter Registry
    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        if (filter) {
            filteredSetApprovalForAll(operator, approved);
        } else {
            super.setApprovalForAll(operator, approved);
        }
    }

    function filteredSetApprovalForAll(address operator, bool approved)
        public
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
    {
        if (filter) {
            filteredApprove(operator, tokenId);
        } else {
            super.approve(operator, tokenId);
        }
    }

    function filteredApprove(address operator, uint256 tokenId)
        public
        payable
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        if (filter) {
            filteredTransferFrom(from, to, tokenId);
        } else {
            super.transferFrom(from, to, tokenId);
        }
    }

    function filteredTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        if (filter) {
            filteredSafeTransferFrom(from, to, tokenId);
        } else {
            super.safeTransferFrom(from, to, tokenId);
        }
    }

    function filteredSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        if (filter) {
            filteredSafeTransferFrom(from, to, tokenId, data);
        } else {
            super.safeTransferFrom(from, to, tokenId, data);
        }
    }

    function filteredSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}