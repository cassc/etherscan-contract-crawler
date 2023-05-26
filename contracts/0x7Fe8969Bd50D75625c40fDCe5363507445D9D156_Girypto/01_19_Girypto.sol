// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../lib/Utils/OwnableExtension.sol";
import "../lib/Token/ERC721/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Girypto is OwnableExtension, ERC721A, DefaultOperatorFilterer {
    string public baseURI;

    constructor(string memory _uri, address _wallet)
        ERC721A("Girypto", "GIR", 1000, 3000)
    {
        baseURI = _uri;

        // defaultRecipents
        _recipient = _wallet;
        // defaultRoyalties
        defaultBps = 530;
    }
    /*
     * {IERC-2981 function}.
     * Royalties modules
     */
    function setRoyalties(address newRecipient, uint256 bps)
        external
        onlyOwner
    {
        require(
            newRecipient != address(0),
            "Royalties: new recipient is the zero address"
        );
        _recipient = newRecipient;
        defaultBps = bps;
    }

    /** Metadata **/
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /** Mint **/
    function massMint(address to, uint256 amount) external _OnlyControllers {
        _safeMint(to, amount);
    }

    /*
     * {IERC721-approve function}.
     * Opensea modules
     */
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

    /*
     * {IERC721-transfer function}.
     * Opensea modules
     */
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
        super.safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }
}