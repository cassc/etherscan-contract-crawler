// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./lib/IWCNFTErrorCodes.sol";
import "./lib/WCNFTToken.sol";

contract JohnRivas is
    ReentrancyGuard,
    WCNFTToken,
    IWCNFTErrorCodes,
    DefaultOperatorFilterer,
    ERC1155Supply
{
    using Strings for uint256;
    struct AirdropData {
        address receiver;
        uint8 tokenId; // expecting token ids less than 256
    }

    string private _baseURIextended;
    string public provenance;

    // for opensea
    string public name = "John Rivas";
    string public symbol = "JOHNRIVAS";
    uint256[] public maxSupply;

    error InvalidTokenId();
    error UnequalArrayLengths();

    /**************************************************************************
     * Constructor
     */
    constructor(uint256[] memory maxSupplyPerId) ERC1155("") WCNFTToken() {
        uint256 numberOfIds = maxSupplyPerId.length;

        maxSupply = new uint256[](numberOfIds);
        for (uint256 index; index < numberOfIds; index++) {
            maxSupply[index] = maxSupplyPerId[index];
        }
    }

    /***************************************************************************
     * Tokens
     */
    /**
     * @dev sets the base uri
     */
    function setBaseURI(string memory baseURI_)
        external
        onlyRole(SUPPORT_ROLE)
    {
        _baseURIextended = baseURI_;
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}
     */
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            bytes(_baseURIextended).length > 0
                ? string(abi.encodePacked(_baseURIextended, tokenId.toString()))
                : "";
    }

    /**
     * @dev sets the provenance hash
     * @param provenance_ the provenance hash
     */
    function setProvenance(string memory provenance_)
        external
        onlyRole(SUPPORT_ROLE)
    {
        provenance = provenance_;
    }

    /**
     * @dev checks to see if amount of tokens to be minted would exceed the maximum supply allowed
     * @param tokenId the token id
     * @param numberOfTokens the amount of tokens to mint for the related tokenId
     */
    function supplyAvailable(uint256 tokenId, uint256 numberOfTokens)
        public
        view
        returns (bool)
    {
        if (tokenId >= maxSupply.length) revert InvalidTokenId();
        if (totalSupply(tokenId) + numberOfTokens > maxSupply[tokenId])
            revert ExceedsMaximumSupply();

        return true;
    }

    /**
     * @dev executes an airdrop
     * @param data an array of the struct AirdropData
     */
    function airdrop(AirdropData[] calldata data)
        external
        onlyRole(SUPPORT_ROLE)
        nonReentrant
    {
        uint256 airdropLength = data.length;

        for (uint256 index; index < airdropLength; index++) {
            address receiver = data[index].receiver;
            uint256 tokenId = data[index].tokenId;
            uint256 numberOfTokens = 1;

            supplyAvailable(tokenId, numberOfTokens);
            _mint(receiver, tokenId, numberOfTokens, "");
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, WCNFTToken)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /***************************************************************************
     * Operator Filterer
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}