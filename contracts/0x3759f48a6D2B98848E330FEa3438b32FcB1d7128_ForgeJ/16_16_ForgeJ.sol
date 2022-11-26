// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

//----------------------------------
//----------------------------------
//----------------------------------
//----------------------------------
//---------- width 36 for decoration

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract ForgeJ is Ownable, ERC20Votes {

  constructor (address recipient)
    ERC20("ForgeJ3", "FJ3")
    ERC20Permit("ForgeJ3")
  {
    // Mint entire supply and send to recipient
    _mint(recipient, 1e9 * 1e18); // One billion with eighteen decimals

    // No contract owner for simplicity, security, and decentralization
    renounceOwnership();
  }
}