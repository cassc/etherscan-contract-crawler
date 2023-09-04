// SPDX-License-Identifier: UNLICENCED

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

/**
This base contract provides a combination of common base inheritance for PlanetX NFTs.
It includes: Royalties (ERC2981), OperatorFiltering (OperatorFilterRegistry)
and overries for basic ERC721A functionality - start token id and base uri.
 */
contract XNFTRoyaltyBase is DefaultOperatorFilterer, ERC721AQueryable, ERC2981, Ownable {
    // the base URI for the metadata
    string public baseURI;

    // the URI for the contract level metadata
    // @dev see https://docs.opensea.io/docs/contract-level-metadata
    string private contractMetadataURI;

    event RoyaltyChanged(address indexed receiver, uint96 feeNumerator);
    event BaseURISet(string baseURI);
    error EmptyBaseURI();

    constructor(
        string memory name,
        string memory symbol,
        uint96 royalty,
        address receiver
    ) ERC721A(name, symbol) {
        // set the default royalty
        _setDefaultRoyalty(receiver, royalty);
    }

    /**
     * @dev override from ERC721A
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev overriding from ERC721: start at the 1st token instead of 0
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @dev sets the base uri for {_baseURI}
     */
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        if (bytes(newBaseURI).length == 0) {
            revert EmptyBaseURI();
        }

        baseURI = newBaseURI;
        emit BaseURISet(newBaseURI);
    }

    // contract level metadata
    function contractURI() external view returns (string memory) {
        return contractMetadataURI;
    }

    function setContractURI(string calldata newURI) external payable onlyOwner {
        contractMetadataURI = newURI;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC2981, IERC721A, ERC721A) returns (bool) {
        return ERC721A.supportsInterface(interfaceId);
    }

    ////////////////
    // ERC2981 royalty standard
    ////////////////
    /**
     * @dev See {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external payable onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);

        emit RoyaltyChanged(receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty() external payable onlyOwner {
        _deleteDefaultRoyalty();
    }

    ////////////////
    // overrides for using OpenSea's OperatorFilter to filter out platforms which are know to not enforce
    // creator earnings
    ////////////////
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //////////
    // end of OpenSea DefaultOperatorFilter overrides
}