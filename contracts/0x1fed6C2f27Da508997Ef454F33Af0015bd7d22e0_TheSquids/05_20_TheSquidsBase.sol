// SPDX-License-Identifier: MIT
// Creator: https://cojodi.com
pragma solidity ^0.8.0;

import "cojodi/contracts/token/ERC721MaxSupply.sol";

contract TheSquidsBase is ERC721MaxSupply {
  constructor() ERC721MaxSupply("The Squids", "TSQ", 2000, "https://minting.dns.army/thesquids/") {}
}