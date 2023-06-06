// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import "./utils/Errors.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @author @0x__jj, @llio (Deca)
contract RightClickSnapshot is ERC721, ReentrancyGuard, AccessControl, Ownable {
  using Address for address;

  uint256 public totalSupply = 0;

  uint256 public constant MAX_SUPPLY = 1024;

  bytes32 public merkleRoot;

  string public baseUri;

  mapping(address => bool) public claimed;

  constructor(
    string memory _baseUri,
    address[] memory _admins
  ) ERC721("Right Click Snapshot", "RCS") {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    for (uint256 i = 0; i < _admins.length; i++) {
      _grantRole(DEFAULT_ADMIN_ROLE, _admins[i]);
    }
    baseUri = _baseUri;
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
    bytes32[] calldata _merkleProof,
    address _holder,
    uint256 _balance
  ) external nonReentrant {
    if (claimed[_holder]) revert AlreadyClaimed();
    if (_balance < 1) revert NoBalance();
    if ((totalSupply + _balance) > MAX_SUPPLY) revert MaxSupplyReached();
    if (msg.sender.isContract()) revert CannotMintFromContract();
    bytes32 leaf = keccak256(abi.encodePacked(_holder, _balance));
    if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf))
      revert NotOnAllowlist();
    claimed[_holder] = true;
    uint256 tokenId = totalSupply;
    totalSupply += _balance;
    for (uint256 i = 0; i < _balance; i++) {
      _safeMint(_holder, tokenId);
      tokenId++;
    }
  }

  function tokenURI(
    uint256 _tokenId
  ) public view override(ERC721) returns (string memory) {
    require(_exists(_tokenId), "RCS: URI query for nonexistent token");
    string memory baseURI = _baseURI();
    require(bytes(baseURI).length > 0, "baseURI not set");
    return string(abi.encodePacked(baseURI));
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