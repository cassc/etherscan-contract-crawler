// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Phygital__v1_0.sol";

contract Phygital__v1_1 is Phygital__v1_0 {
  using ECDSA for bytes32;

  uint16 public minorVersion;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {}

  // Overidden to guard against which users can access
  function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

  // Deploying Phygital__v1_1 initializer
  function initialize__v1_1(string memory _name, string memory _symbol) public initializer {
    Phygital__v1_0.initialize(_name, _symbol);
  }

  function mintNFT(
    bytes memory sig,
    uint256 blockExpiry,
    address recipient,
    uint256 tokenId
  ) public virtual {
    bytes32 message = getClaimSigningHash(blockExpiry, recipient, tokenId).toEthSignedMessageHash();
    require(ECDSA.recover(message, sig) == signVerifier, "Permission to call this function failed");
    require(block.number < blockExpiry, "Sig expired");

    claimNonces[recipient]++;

    _safeMint(recipient, tokenId);
  }
}