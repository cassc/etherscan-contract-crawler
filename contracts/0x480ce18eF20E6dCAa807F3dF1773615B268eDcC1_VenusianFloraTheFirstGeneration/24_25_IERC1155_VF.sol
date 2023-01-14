// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC1155VF {
  event FloraPlanted(address indexed who, uint256 id, uint256 date);
  event PlantedFloraBurned(address indexed who, uint256 id);
}