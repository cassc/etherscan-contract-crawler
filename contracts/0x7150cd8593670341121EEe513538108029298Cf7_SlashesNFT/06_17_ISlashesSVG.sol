// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISlashesSVG {

  // returns a SVG string
  function generateSVG(uint256 tokenId) pure external returns(string memory, string memory);

}