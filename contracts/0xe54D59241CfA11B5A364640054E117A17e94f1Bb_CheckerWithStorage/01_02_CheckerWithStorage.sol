// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./TurfShopEligibilityChecker.sol";

contract CheckerWithStorage is TurfShopEligibilityChecker {
  
  address turfShopAddress;
  mapping(address => uint256) private _mintedPerAddress;

  constructor(address turfShopAddress_) {
    require(turfShopAddress_ != address(0), "Set the Turf Shop address!");
    turfShopAddress = turfShopAddress_;
  }

  function check(address addr, bytes32[] memory merkleProof, bytes memory data) external view returns (bool, uint) {
    require(_mintedPerAddress[addr] == 0, "already minted");
    return (true, 1);
  }

  function confirmMint(address addr, uint256 count) external {
    require(msg.sender == turfShopAddress, "nope");
    _mintedPerAddress[addr] = count;
  }

}