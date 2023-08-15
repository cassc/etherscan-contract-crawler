// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.19;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract GarbageBags is ERC721A, Ownable, ERC2981, DefaultOperatorFilterer {

    uint16 public constant MAX_SUPPLY = 6500;
    string public uriSuffix;
    string public baseTokenURI;
    address private _allowedCaller;

    // Custom error
    error OnlyAllowedCallerError();
    error MaxSupplyReachedError();

    constructor(
        string memory _baseTokenURI
    ) ERC721A("Garbage Bags", "GARBAGEB") {
        baseTokenURI = _baseTokenURI;
        _setDefaultRoyalty(_msgSender(), 650);
    }

    // Modifier

    modifier onlyAllowedCaller() {
        if (_msgSender() != _allowedCaller) revert OnlyAllowedCallerError();
        _;
    }

    /**
     *@notice This is an internal function that returns base URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @notice Airdrop nfts
     * @param receivers address  
     */
    function airdropNfts(
        address[] calldata receivers
    ) external onlyOwner {  
        if (_totalMinted() + receivers.length > MAX_SUPPLY) {
            revert MaxSupplyReachedError();
        } 
        for(uint256 i; i < receivers.length; ) {
            _mint(receivers[i], 1);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Sets the uri suffix
     * @param _uriSuffix string
     */
    function setUriSuffix(string calldata _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    /**
     * @notice Update the base token URI
     * @param _newBaseURI string
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Update caller to burn token
     * @param _caller address
     */
    function setAllowedCaller(address _caller) external onlyOwner {
        _allowedCaller = _caller;
    }

    /**
     * @notice Update royalty information
     * @param receiver address
     * @param numerator uint96
     */
    function setDefaultRoyalty(
        address payable receiver,
        uint96 numerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    /**
     * @notice burn token ids in batch
     * @param tokenIds uint[]
     */
    function burnBatch(uint256[] calldata tokenIds) external onlyAllowedCaller {
        for(uint256 i; i < tokenIds.length; ) {
            _burn(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // Override following ERC721a's method to auto restrict marketplace contract

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal override {
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the URI for `tokenId` token
     * @param tokenId uint
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory base = _baseURI();
        return string(abi.encodePacked(base, _toString(tokenId), uriSuffix));
    }
}