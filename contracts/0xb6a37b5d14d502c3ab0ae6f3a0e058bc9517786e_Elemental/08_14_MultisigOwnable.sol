// SPDX-License-Identifier: CC0-1.0
// Source: https://github.com/tubby-cats/dual-ownership-nft
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';

abstract contract MultisigOwnable is Ownable {
  address public realOwner;

  constructor() {
    realOwner = msg.sender;
  }

  modifier onlyRealOwner() {
    require(
      realOwner == msg.sender,
      'MultisigOwnable: caller is not the real owner'
    );
    _;
  }

  function transferRealOwnership(address newRealOwner) public onlyRealOwner {
    realOwner = newRealOwner;
  }

  function transferLowerOwnership(address newOwner) public onlyRealOwner {
    transferOwnership(newOwner);
  }
}