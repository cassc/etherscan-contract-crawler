// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IGRDS.sol";

interface IGRDSMeta {

  function gridCompleted(uint256 colorsLength) external pure returns (bool);
  function findGridValue(uint _len) external pure returns (uint);
  function fillGrid(string[] memory _colors, string memory _filler) external pure returns (string[] memory);
  function tokenMetadata(IGRDS.GroupingExpanded memory _ge) external view returns (string memory);
  function getFriendlyNames() external view returns(string[25] memory);
  function getFriendlySymbols() external view returns(string[26] memory);

}