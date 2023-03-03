// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../royalties/ERC2981ContractWideRoyalties.sol";
import "../utils/ERC721Metadata.sol";
import "../utils/Administration.sol";
import "../utils/IERC4906.sol";
import "../utils/opensea/DefaultOperatorFilterer.sol";

contract RelicsERC721 is
    ERC721,
    ERC721Metadata,
    IERC4906,
    ERC2981ContractWideRoyalties,
    Administration,
    DefaultOperatorFilterer
{
    uint256 private _maxSupply;
    uint256 private _issuanceCounter;
    uint256 private _burnCounter;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI,
        string memory contractURI,
        address royaltyRecipient,
        uint24 royaltyValue,
        address owner
    ) ERC721(name_, symbol_) Administration(owner) {
        _setBaseURI(baseTokenURI);
        _setContractURI(contractURI);
        _setRoyalties(royaltyRecipient, royaltyValue);
    }

    function totalMinted() public view returns (uint256) {
        return _issuanceCounter;
    }

    function totalBurned() public view returns (uint256) {
        return _burnCounter;
    }

    function totalSupply() public view returns (uint256) {
        unchecked {
            return _issuanceCounter - _burnCounter;
        }
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function setMaxSupply(uint256 maxSupply_) external isAdmin {
        if (_maxSupply > 0) revert MaxSupplyUnchangeable();
        _maxSupply = maxSupply_;
    }

    function setRoyalties(address recipient, uint24 value) external isAdmin {
        _setRoyalties(recipient, value);
    }

    function setContractURI(string memory contractURI) external isAdmin {
        _setContractURI(contractURI);
    }

    function setBaseURI(string memory uri) external isAdmin {
        _setBaseURI(uri);
        emit BatchMetadataUpdate(1, totalMinted());
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI_) external isAdmin {
        _setTokenURI(tokenId, tokenURI_);
        emit MetadataUpdate(tokenId);
    }

    function burn(uint256 tokenId) public virtual {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert TransferCallerNotOwnerNorApproved();
        }
        _burn(tokenId);
    }

    function mint(address to, uint256 tokenId) external virtual isMinter whenNotPaused {
        _mint(to, tokenId);
    }

    // Overides

    function _mint(address to, uint256 tokenId) internal virtual override {
        unchecked {
            _issuanceCounter++;
            if (_maxSupply > 0 && totalMinted() > _maxSupply) {
                revert MaxSupplyReached();
            }
        }

        super._mint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721Metadata) returns (string memory) {
        return ERC721Metadata.tokenURI(tokenId);
    }

    function _baseURI() internal view virtual override(ERC721, ERC721Metadata) returns (string memory) {
        return ERC721Metadata._baseURI();
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165, ERC2981Base, Administration)
        returns (bool)
    {
        return
            interfaceId == bytes4(0x49064906) ||
            interfaceId == type(ERC721Metadata).interfaceId ||
            interfaceId == type(ERC2981Base).interfaceId ||
            interfaceId == type(ERC2981ContractWideRoyalties).interfaceId ||
            interfaceId == type(Administration).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    //////////////  ERRORS  //////////////
    error MaxSupplyUnchangeable();
    error MaxSupplyReached();
    error TransferCallerNotOwnerNorApproved();
    /////////////////////////////////////
}