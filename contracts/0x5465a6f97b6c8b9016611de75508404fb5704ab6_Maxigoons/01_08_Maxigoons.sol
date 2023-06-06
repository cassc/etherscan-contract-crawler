//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./NFT.sol";

contract Maxigoons is NFT {
  constructor(address vrfCoordinator, address linkToken)
    ERC721a("Maxigoons", "GOON")
    NFT(
      7007, // Max supply
      707, // Reserve amount
      100, // Max per wallet
      "bafybeicxiym4ou5ephvt4j66if3axll3s3uq7axspgcdjr5tvrtrfboqsa", // Content ID (CID)
      "bab93ab37b236a32545c4bb2239ac9da276bc18324bcdcf0d86e0d225299db7b", // Provenance Hash
      0x9d14CAea98d6Ef30Ae169c361D2540dd680Bc280, // Vault address
      vrfCoordinator,
      linkToken
    )
  {}

  function claim(bytes32[] memory proof) public {
    _sell(0, 1, 0, proof);
  }

  function presale(uint256 amount, bytes32[] memory proof) public payable {
    _sell(1, amount, msg.value, proof);
  }

  function buy(uint256 amount) public payable {
    _sell(2, amount, msg.value, new bytes32[](0));
  }

  function mint(
    uint256 index,
    uint256 amount,
    bytes32[] memory proof
  ) public payable {
    _sell(index, amount, msg.value, proof);
  }
}