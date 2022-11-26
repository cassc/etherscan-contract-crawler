// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./TitleEscrow.sol";
import "./interfaces/ITitleEscrowFactory.sol";

contract TitleEscrowFactory is ITitleEscrowFactory {
  address public override implementation;

  constructor() {
    implementation = address(new TitleEscrow());
  }

  function create(uint256 tokenId) external override returns (address) {
    bytes32 salt = keccak256(abi.encodePacked(msg.sender, tokenId));
    address titleEscrow = Clones.cloneDeterministic(implementation, salt);
    TitleEscrow(titleEscrow).initialize(msg.sender, tokenId);

    emit TitleEscrowCreated(titleEscrow, msg.sender, tokenId);

    return titleEscrow;
  }

  function getAddress(address tokenRegistry, uint256 tokenId) external view override returns (address) {
    return Clones.predictDeterministicAddress(implementation, keccak256(abi.encodePacked(tokenRegistry, tokenId)));
  }
}