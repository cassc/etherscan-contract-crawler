// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {LicenseVersion, CantBeEvil} from "@a16z/contracts/licenses/CantBeEvil.sol";

string constant CollectionName = "Cursed Emojis";
string constant CollectionSymbol = "CursedEmojis";

/// @title Cursed Emojis
/// @dev See also ERC4096
contract CursedEmojis is ERC721, ERC721URIStorage, ERC721Enumerable, AccessControl, Ownable, CantBeEvil {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant CURSE_GIVER_ROLE = keccak256("CURSE_GIVER_ROLE");

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _totalRemixes;
    EnumerableMap.AddressToUintMap private mintersMap;

    uint256 private constant _supplyLimit = 512; // global max
    uint256 private _mintsPerAccountLimit; // single account max
    uint256 private _remixLimit; // global max

    mapping(uint256 => uint256) private _remixes; // token:count map
    mapping(uint256 => uint256) private _remaining_remixes; // token:credits map

    event GenesisMint(address indexed from, string uri);
    event Remix(address indexed from, uint256 indexed tokenId, string uri);
    /// @dev ERC4096
    event MetadataUpdate(uint256 indexed tokenId);

    constructor()
    ERC721(CollectionName, CollectionSymbol)
    CantBeEvil(LicenseVersion.CBE_NECR)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(CURSE_GIVER_ROLE, msg.sender);

        _remixLimit = 1;
        _mintsPerAccountLimit = 1;
    }

    /// @notice CAREFUL, this is a permanent lockdown of contract admin
    function lockForever() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _revokeRole(CURSE_GIVER_ROLE, msg.sender);
    }

    //access control functions

    /// @dev add selected wallet to on-chain minting allowlist
    function curse(address account) public onlyRole(CURSE_GIVER_ROLE) {
        _grantRole(MINTER_ROLE, account);
    }

    /// @dev remove selected wallet from on-chain minting allowlist
    function unCurse(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, account);
    }

    /// @notice whether or not account is allowed to mint
    function isCursed(address account) public view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    function updateMetadata(uint256 tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        emit MetadataUpdate(tokenId);
    }

    function _genesisMint(address to) private {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        string memory uri2 = _generateUri(address(this), tokenId, _remixes[tokenId]);
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri2);
        _remaining_remixes[tokenId] = 1;
        emit GenesisMint(to, uri2);
    }

    function genesisMint() public onlyRole(MINTER_ROLE) {
        require ((totalSupply() < _supplyLimit), "Genesis Mint: Cannot mint, total supply limit reached");
        ( , uint256 accountMintCount) = EnumerableMap.tryGet(mintersMap, msg.sender);
        require (( accountMintCount < _mintsPerAccountLimit), "Genesis Mint: Cannot mint, allowed mints per account limit reached");
        EnumerableMap.set(mintersMap, msg.sender, accountMintCount + 1);

        _genesisMint(msg.sender);
    }

    function _generateUri(address addy, uint256 tokenId, uint256 remixCount) pure internal returns (string memory) {
        return string(
            abi.encodePacked(
                "https://cursedemojis.world/",
                Strings.toHexString(addy),
                "/",
                Strings.toHexString(tokenId),
                "/",
                Strings.toHexString(remixCount),
                ".json"
            ));
    }

    function remix(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        require(_exists(tokenId), "Remix: token does not exist.");
        require(_remixes[tokenId] < _remixLimit, "Remix: remix limit already reached.");
        require(0 < _remaining_remixes[tokenId], "Remix: no remixes left.");
        _remix(tokenId);
    }

    function _remix(uint256 tokenId) private {
        _remixes[tokenId] += 1;
        _remaining_remixes[tokenId] -= 1;
        _totalRemixes.increment();
        string memory remixedUri = _generateUri(address(this), tokenId, _remixes[tokenId]);
        _setTokenURI(tokenId, remixedUri);
        emit Remix(_msgSender(), tokenId, remixedUri);
        emit MetadataUpdate(tokenId);
    }

    function totalRemixes() public view returns (uint256) { 
        return _totalRemixes.current();
    }

    function getRemixCount(uint256 tokenId) public view returns (uint256) {
        return _remixes[tokenId];
    }

    function setMintsPerAccountLimit(uint256 limit) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _mintsPerAccountLimit = limit;
    }

    function getMintsPerAccountLimit() public view returns (uint256) {
        return _mintsPerAccountLimit;
    }

    function setRemixLimit(uint256 limit) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _remixLimit = limit;
    }

    function getRemixLimit() public view returns (uint256) {
        return _remixLimit;
    }

    function getTokenRemixesRemaining(uint256 tokenId) public view returns (uint256) {
        return _remaining_remixes[tokenId];
    }

    function setTokenRemixes(uint256 tokenId, uint256 remixes) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _remaining_remixes[tokenId] = remixes;
    }


    // required overrides

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(CantBeEvil, ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }
}