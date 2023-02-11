// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "../common/AgencyNFT.sol";

contract StampNFT is AgencyNFT {
  constructor(string memory name_, string memory symbol_)
    AgencyNFT(name_, symbol_)
  {}
}