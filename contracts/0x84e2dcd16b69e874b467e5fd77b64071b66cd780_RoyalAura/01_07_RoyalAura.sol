// SPDX-License-Identifier: Unliscensed

pragma solidity ^0.8.17;

import "../CosmeticERC721A/CosmeticERC721A.sol";
import "../IDailyCargo.sol";

contract RoyalAura is CosmeticERC721A {
  
  address dailyCargo;
  uint256 claimableUntil;

  mapping(address => bool) claimed;

  constructor() CosmeticERC721A("RoyalAura", "RA") {
    dailyCargo = 0xCa6D7604ae55BA1bA864c26692a91979f25Cdb96;
    URI = "ipfs://Qmb54iL6FoDV7r2XWjPHcHewAd8e1DHfktDTwWNRiFJ2SV";
    claimableUntil = block.timestamp + 1 days;
  }

  function isEligible(address _address) public view override returns (bool) {
    IDailyCargo cargo = IDailyCargo(dailyCargo);
    require(!(claimed[_address]), "You have already claimed your cosmetic.");
    require(block.timestamp <= claimableUntil, "The claim has expired.");
    uint256 addressStreak = cargo.getAddressStreak(_address);

    return addressStreak >= 7 ? true : false;
  }

  function claim(address _to) public override onlyCosmeticRegistry(msg.sender) {
    claimed[_to] = true;
    super.claim(_to);
  }

  function setDailyCargo(address _address) public onlyOwner {
    dailyCargo = _address;
  }

  function getDailyCargo() public view returns (address) {
    return dailyCargo;
  }

  function setClaimableUntil(uint256 _claimableUntil) public onlyOwner {
    claimableUntil = _claimableUntil;
  }

  function getClaimableUntil() public view returns (uint256) {
    return claimableUntil;
  }
}