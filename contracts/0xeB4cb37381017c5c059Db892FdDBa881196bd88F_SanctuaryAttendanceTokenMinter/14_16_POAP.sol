// SPDX-License-Identifier: GPL-3.0
// presented by Wildxyz

pragma solidity ^0.8.6;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";


/* POAP

Locks all transfer and approve methods

*/
abstract contract POAP is
    Ownable,
    IERC721,
    ERC721
{
    bool public locked = true; // no setter for this

    uint256 public _currentTokenId;
    uint256 public maxSupply;

    string public baseURI;

    event TokenMint(address _to, uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 _maxSupply,
        string memory _baseURI
    ) ERC721(name_, symbol_) {
        maxSupply = _maxSupply;
        baseURI = _baseURI;
    }

    modifier isLocked() {
        require(false, "POAP: Contract is locked");
        _;
    }


    // ONLY OWNER METHODS

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
        emit BatchMetadataUpdate(0, maxSupply - 1);
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }


    // PUBLIC METHODS
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function totalSupply() public view returns (uint256) {
        return _currentTokenId;
    }


    // LOCK ALL TRANSFER AND APPROVAL METHODS

    function isApprovedForAll(address _owner, address operator)
        public
        view
        override(IERC721, ERC721)
        isLocked
        returns (bool)
    {
        //return super.isApprovedForAll(_owner, operator);
    }

    function approve(address to, uint256 tokenId)
        public
        virtual
        override(IERC721, ERC721)
        isLocked
    {
        //super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(IERC721, ERC721)
        isLocked
    {
        //super.setApprovalForAll(operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721, ERC721) isLocked {
        //super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721, ERC721) isLocked {
        //super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(IERC721, ERC721) isLocked {
        //super.safeTransferFrom(from, to, tokenId, data);
    }


    // INTERNAL METHODS

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721) {
        // only allow minting only (aka from 0 address)
        require(from == address(0), "POAP: Only minting allowed");

        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _mintTo(address to, uint256 tokenId) internal returns (uint256) {
        _mint(to, tokenId);
        emit TokenMint(to, tokenId);

        return tokenId;
    }
}