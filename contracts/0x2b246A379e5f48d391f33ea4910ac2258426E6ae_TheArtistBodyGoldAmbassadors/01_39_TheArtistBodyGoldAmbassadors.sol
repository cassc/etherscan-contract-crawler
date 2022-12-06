// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@nefty/base-contracts/contracts/ERC721ADropBase.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract TheArtistBodyGoldAmbassadors is
    ERC721ADropBase,
    DefaultOperatorFilterer
{
    string public provenance;
    string private _baseURIExtended;

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint32 _maxSupply,
        string memory _provenance
    )
        ERC721ADropBase(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _maxSupply
        )
    {
        provenance = _provenance;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}