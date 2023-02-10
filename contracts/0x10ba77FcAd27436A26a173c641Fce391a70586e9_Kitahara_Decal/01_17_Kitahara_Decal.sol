// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./utils/Errors.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @author @0x__jj, @llio (Deca)
contract Kitahara_Decal is ERC721, ReentrancyGuard, AccessControl, Ownable {
  using Address for address;
  using Strings for *;

  event ArtistMinted(uint256 numberOfTokens, uint256 remainingArtistSupply);

  mapping(address => bool) public minted;

  uint256 public totalSupply = 0;

  uint256 public constant MAX_SUPPLY = 100;

  bytes32 public merkleRoot;

  uint256 public artistMaxSupply;

  uint256 public artistSupply;

  address public artist;

  string public baseUri;

  constructor(
    string memory _baseUri,
    address[] memory _admins,
    uint256 _artistMaxSupply,
    address _artist
  ) ERC721("Decal by Keiko Kitahara", "DECAL") {
    if (_artistMaxSupply > MAX_SUPPLY) revert MaxSupplyReached();
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    for (uint256 i = 0; i < _admins.length; i++) {
      _grantRole(DEFAULT_ADMIN_ROLE, _admins[i]);
    }
    baseUri = _baseUri;
    artistMaxSupply = _artistMaxSupply;
    artist = _artist;
  }

  function setArtist(address _artist) external onlyRole(DEFAULT_ADMIN_ROLE) {
    artist = _artist;
  }

  function setArtistMaxSupply(
    uint256 _artistMaxSupply
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if ((_artistMaxSupply - artistSupply) > (MAX_SUPPLY - totalSupply))
      revert MaxArtistSupplyReached();
    artistMaxSupply = _artistMaxSupply;
  }

  function setMerkleRoot(
    bytes32 _merkleRoot
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    merkleRoot = _merkleRoot;
  }

  function setBaseUri(
    string memory _newBaseUri
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    baseUri = _newBaseUri;
  }

  function mint(
    bytes32[] calldata _merkleProof
  ) external nonReentrant returns (uint256 tokenId) {
    if (minted[msg.sender]) revert AlreadyMinted();
    if (totalSupply >= MAX_SUPPLY) revert MaxSupplyReached();
    if (publicSupplyRemaining() < 1) revert MaxPublicSupplyReached();
    if (msg.sender.isContract()) revert CannotMintFromContract();
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf))
      revert NotOnAllowlist();
    minted[msg.sender] = true;
    tokenId = totalSupply;
    totalSupply++;
    _safeMint(msg.sender, tokenId);
  }

  function artistMintForAdmin(
    uint256 _numberOfTokens
  ) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_numberOfTokens == 0) revert CannotMintZero();
    if (artist == address(0)) revert NoArtist();
    uint256 remaining = artistMaxSupply - artistSupply;
    if (remaining == 0) revert MaxArtistSupplyReached();
    _numberOfTokens = uint256(Math.min(_numberOfTokens, remaining));
    uint256 tokenId = totalSupply;
    for (uint256 i = 0; i < _numberOfTokens; i++) {
      _safeMint(artist, tokenId);
      tokenId++;
    }
    artistSupply += _numberOfTokens;
    totalSupply = tokenId;
    emit ArtistMinted(_numberOfTokens, remaining);
  }

  function artistMint(uint256 _numberOfTokens) external nonReentrant {
    if (_numberOfTokens == 0) revert CannotMintZero();
    if (artist == address(0)) revert NoArtist();
    if (msg.sender != artist) revert NotArtist();
    uint256 remaining = artistMaxSupply - artistSupply;
    if (remaining == 0) revert MaxArtistSupplyReached();
    _numberOfTokens = uint256(Math.min(_numberOfTokens, remaining));
    uint256 tokenId = totalSupply;
    for (uint256 i = 0; i < _numberOfTokens; i++) {
      _safeMint(msg.sender, tokenId);
      tokenId++;
    }
    artistSupply += _numberOfTokens;
    totalSupply = tokenId;
    emit ArtistMinted(_numberOfTokens, remaining);
  }

  function publicSupplyRemaining() public view returns (uint256) {
    return MAX_SUPPLY - totalSupply - (artistMaxSupply - artistSupply);
  }

  function artistSupplyRemaining() external view returns (uint256) {
    return artistMaxSupply - artistSupply;
  }

  function tokenURI(
    uint256 _tokenId
  ) public view override(ERC721) returns (string memory) {
    require(_exists(_tokenId), "DECAL: URI query for nonexistent token");
    string memory baseURI = _baseURI();
    require(bytes(baseURI).length > 0, "baseURI not set");
    return string(abi.encodePacked(baseURI, _tokenId.toString()));
  }

  function getTokensOfOwner(
    address owner_
  ) external view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(owner_);
    uint256[] memory tokenIds = new uint256[](tokenCount);
    uint256 seen = 0;
    for (uint256 i = 0; i < totalSupply; i++) {
      if (ownerOf(i) == owner_) {
        tokenIds[seen] = i;
        seen++;
      }
      if (seen == tokenCount) break;
    }
    return tokenIds;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _baseURI() internal view override(ERC721) returns (string memory) {
    return baseUri;
  }
}