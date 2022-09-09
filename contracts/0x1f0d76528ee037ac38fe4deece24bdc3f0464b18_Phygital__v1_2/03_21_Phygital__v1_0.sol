// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Phygital__v1_0 is Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
  using ECDSA for bytes32;

  address public signVerifier;
  string public baseURI;

  mapping(address => uint256) public claimNonces;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {}

  function initialize(string memory name, string memory symbol) public initializer {
    __ERC721_init(name, symbol);
    __UUPSUpgradeable_init();
    __Ownable_init();

    signVerifier = 0xF504941EF7FF8f24DC0063779EEb3fB12bAc8ab7;
    baseURI = "https://iyk.app/api/metadata/";
  }

  // Overidden to guard against which users can access
  function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

  function getClaimNonce(address recipient) external view virtual returns (uint256) {
    return claimNonces[recipient];
  }

  function getClaimSigningHash(
    uint256 blockExpiry,
    address recipient,
    uint256 tokenId
  ) public view virtual returns (bytes32) {
    return keccak256(abi.encodePacked(blockExpiry, recipient, tokenId, address(this), claimNonces[recipient]));
  }

  function getSignVerifier() external view virtual returns (address) {
    return signVerifier;
  }

  function setSignVerifier(address verifier) external virtual onlyOwner {
    signVerifier = verifier;
  }

  function setBaseURI(string memory uri) external virtual onlyOwner {
    baseURI = uri;
  }

  function mint(address recipient, uint256 tokenId) external virtual onlyOwner {
    _safeMint(recipient, tokenId);
  }

  function claimNFT(
    bytes memory sig,
    uint256 blockExpiry,
    address recipient,
    uint256 tokenId
  ) public virtual {
    bytes32 message = getClaimSigningHash(blockExpiry, recipient, tokenId).toEthSignedMessageHash();
    require(ECDSA.recover(message, sig) == signVerifier, "Permission to call this function failed");
    require(block.number < blockExpiry, "Sig expired");

    address from = ownerOf(tokenId);
    require(from != address(0));

    claimNonces[recipient]++;

    _safeTransfer(from, recipient, tokenId, "");
  }

  // Override transfer from functions and make them useless
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {}

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {}

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {}

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
}