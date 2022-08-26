// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Errors.sol";
import "./Ownable.sol";
import "./Base64.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @author @0x__jj, @llio (Deca)
contract Yun_Decal is ERC721, ReentrancyGuard, AccessControl, Ownable {
  using Address for address;
  using Strings for *;

  mapping(address => bool) public minted;

  uint256 public totalSupply = 0;

  uint256 public constant MAX_SUPPLY = 100;

  bytes32 public merkleRoot;

  string public baseUri;

  constructor(string memory _baseUri, address[] memory _admins)
    ERC721("Decal by Grant Yun", "DECAL")
  {
    _setOwnership(msg.sender);
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    for (uint256 i = 0; i < _admins.length; i++) {
      _grantRole(DEFAULT_ADMIN_ROLE, _admins[i]);
    }
    baseUri = _baseUri;
  }

  function setMerkleRoot(bytes32 _merkleRoot)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    merkleRoot = _merkleRoot;
  }

  function setOwnership(address _newOwner)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _setOwnership(_newOwner);
  }

  function setBaseUri(string memory _newBaseUri)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    baseUri = _newBaseUri;
  }

  function mint(bytes32[] calldata _merkleProof)
    external
    nonReentrant
    returns (uint256)
  {
    if (totalSupply >= MAX_SUPPLY) revert MaxSupplyReached();
    if (minted[msg.sender]) revert AlreadyMinted();
    if (msg.sender.isContract()) revert CannotMintFromContract();
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf))
      revert ProofInvalidOrNotInAllowlist();

    uint256 tokenId = totalSupply;
    totalSupply++;
    minted[msg.sender] = true;
    _safeMint(msg.sender, tokenId);
    return tokenId;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
  {
    require(_exists(_tokenId), "DECAL: URI query for nonexistent token");
    string memory baseURI = _baseURI();
    require(bytes(baseURI).length > 0, "baseURI not set");
    return string(abi.encodePacked(baseURI, _tokenId.toString()));
  }

  function getTokensOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](tokenCount);
    uint256 seen = 0;
    for (uint256 i; i < totalSupply; i++) {
      if (ownerOf(i) == _owner) {
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
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _baseURI() internal view override(ERC721) returns (string memory) {
    return baseUri;
  }
}