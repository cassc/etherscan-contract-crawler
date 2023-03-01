// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IGRDS.sol";

interface IGRDSpecial {
  function isGrid(uint _gridval, string[] memory hexColors, string[] memory symbols) external view returns (string memory);
  function customMeta(IGRDS.NameCount[] memory colors,  IGRDS.NameCount[] memory symbols) external view returns (IGRDS.NameCount[] memory,  IGRDS.NameCount[] memory);

}