// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "../access/Ownable.sol";
import "./ERC721Lockable.sol";
import "./ERC721TimeTrackable.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

error MintIsInactive();

/**
 * @title ERC721Preset
 * @dev ERC721 contract with several extensions implemented
 * @author North Technologies
 * @custom:version 1.2
 * @custom:date 2 May 2022
 *
 * @custom:changelog
 * 
 * v1.1
 * - Implemented new ERC721Lockable that allows for address locking
 * - Implemented new ERC721TimeTrackable for more efficient storage of block time in uint64
 * - Removed provenance as that should be an extension
 * - Used error objects for reverting
 * - flipping locks is external to save gas
 *
 * v1.2
 * - Added a light version of OpenZeppelin Ownable so public services can call the owner() function

 */
abstract contract ERC721Preset is
    AccessControl,
    Ownable,
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Lockable,
    ERC721TimeTrackable
{
    using Counters for Counters.Counter;

    bytes32 public constant STAFF_ROLE = keccak256("STAFF_ROLE");
    bytes32 public constant LOCK_ROLE = keccak256("LOCK_ROLE");

    string public baseURI;
    bool public mintIsActive;

    Counters.Counter private _tokenIdCounter;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(STAFF_ROLE, msg.sender);
        _grantRole(LOCK_ROLE, msg.sender);
    }

    function flipLock(uint256 tokenId) external onlyRole(LOCK_ROLE) {
        _flipLock(tokenId);
    }

    function flipAddressLock(address _address) external onlyRole(LOCK_ROLE) {
        _flipAddressLock(_address);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseUri) external onlyRole(STAFF_ROLE) {
        baseURI = newBaseUri;
    }

    function _safeMint(address to) internal returns (uint256) {
        if(!mintIsActive) revert MintIsInactive();

        uint256 tokenId = _tokenIdCounter.current() + 1;
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();

        return tokenId;
    }

    function flipMintActive() external onlyRole(STAFF_ROLE) {
        mintIsActive = !mintIsActive;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable, ERC721TimeTrackable, ERC721Lockable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}