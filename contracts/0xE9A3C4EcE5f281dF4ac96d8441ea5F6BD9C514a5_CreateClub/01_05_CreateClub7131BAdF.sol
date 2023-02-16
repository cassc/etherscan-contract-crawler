// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721CreatorEthereum.sol";

contract CreateClub is ERC721Creator  {
  constructor() ERC721Creator ("Create Club", "CR8") {}
}