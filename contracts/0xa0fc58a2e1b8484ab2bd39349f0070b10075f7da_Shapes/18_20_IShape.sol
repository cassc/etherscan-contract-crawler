// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IShape {

  // get the name of the shape
  function name() pure external returns (string memory);

  // returns a SVG string
  function generateSVG(uint256 tokenId) pure external returns(
    string memory, // svg
    string memory // attribbutes
  );

}