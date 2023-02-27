// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "../../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "../../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import {EIP712} from "../../lib/openzeppelin-contracts/contracts/utils/cryptography/draft-EIP712.sol";
import {ERC721Votes} from "../../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/draft-ERC721Votes.sol";
import {Counters} from "../../lib/openzeppelin-contracts/contracts/utils/Counters.sol";

contract Passport is ERC721, AccessControl, EIP712, ERC721Votes {
    using Counters for Counters.Counter;

    error Disabled();

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TRANSFERER_ROLE = keccak256("TRANSFERER_ROLE");
    Counters.Counter private _tokenIdCounter;
    string private baseURI;

    constructor(address owner, string memory name_, string memory symbol_, string memory baseURI_)
        ERC721(name_, symbol_)
        EIP712(name_, "1")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(MINTER_ROLE, owner);
        _grantRole(TRANSFERER_ROLE, owner);
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function updateBaseURI(string memory newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = newBaseURI;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function safeMint(address to) external onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    // Configure the approval functionality to return expected values
    function approve(
        address,
        /* to */
        uint256 /* tokenId */
    ) public pure override {
        revert Disabled();
    }

    function setApprovalForAll(
        address,
        /* operator */
        bool /* approved */
    ) public pure override {
        revert Disabled();
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        _requireMinted(tokenId);

        return address(0);
    }

    // Make sure the token is only transferable by the TRANSFERRER_ROLE

    function isApprovedForAll(
        address,
        /* owner */
        address operator /* operator */
    ) public view override returns (bool) {
        return hasRole(TRANSFERER_ROLE, operator);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
        _requireMinted(tokenId);
        return isApprovedForAll(address(0), spender);
    }

    // To make sensible error messages
    function transferFrom(address from, address to, uint256 tokenId) public override onlyRole(TRANSFERER_ROLE) {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyRole(TRANSFERER_ROLE)
    {
        _safeTransfer(from, to, tokenId, data);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override (ERC721, ERC721Votes)
    {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}