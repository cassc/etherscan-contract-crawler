// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721A.sol";
contract StarcatchersInterface is ERC721A {
  constructor(uint128) ERC721A("Starcatchers", "STAR") {}
}