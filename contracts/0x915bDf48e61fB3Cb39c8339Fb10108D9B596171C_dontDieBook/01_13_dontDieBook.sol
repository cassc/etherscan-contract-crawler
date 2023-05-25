// SPDX-License-Identifier: MIT

/**
*   @title Survive All Apocalypses (AKA Don't Die Book)
*   @author Transient Labs
*   @notice ERC721 smart contract with access control and optimized for airdrop
*   Copyright (C) 2021 Transient Labs
*/

pragma solidity ^0.8.0;

import "ERC721.sol";
import "AccessControl.sol";
import "Counters.sol";

contract dontDieBook is ERC721, AccessControl {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    string private _baseTokenURI;
    bytes32 public constant ADMIN = keccak256("ADMIN");
    uint256 public _totalSupply = 892;

    /**
    *   @notice constructor for this contract
    *   @dev grants ADMIN role to contract deployer
    *   @dev name and symbol are hardcoded in from the start
    */
    constructor() ERC721("Dont Die", "Book") {
        _grantRole(ADMIN, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
    *   @notice function to view total supply
    *   @return uint256 with supply
    */
    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    /**
    *   @notice override supportsInterface function since both ERC721 and AccessControl utilize it
    *   @dev see {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);       
    }

    /**
    *   @notice sets the baseURI for the ERC721 tokens
    *   @dev requires ADMIN role
    *   @param uri is the base URI set for each token
    */
    function setBaseURI(string memory uri) public onlyRole(ADMIN) {
        _baseTokenURI = uri;
    }

    /**
    *   @notice override standard ERC721 base URI
    *   @dev doesn't require access control since it's internal
    *   @return string representing base URI
    */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
    *   @notice mint function in batches
    *   @dev requires ADMIN access
    *   @dev converts token id to the appropriate tokenURI string
    *   @param addresses is an array of addresses to mint to
    */
    function batchMint(address[] memory addresses) public onlyRole(ADMIN) {
        for (uint256 i = 0; i < addresses.length; i++) {
            _tokenIds.increment();
            _safeMint(addresses[i], _tokenIds.current());
        }
    }

    /**
    *   @notice single mint function
    *   @dev requires ADMIN access
    *   @param address_ is the address to mint to
    */
    function mint(address address_) public onlyRole(ADMIN) {
        _tokenIds.increment();
        _safeMint(address_, _tokenIds.current());
    }

    /**
    *   @notice burn function for owners to use at their discretion
    *   @dev requires the msg sender to be the owner or an approved delegate
    *   @param tokenId is the token ID to burn
    */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Error: Caller for burning is not approved nor owner");
        _burn(tokenId);
    }
}