// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IWRLD_Name_Service_Metadata is IERC165 {
  function getMetadata(string memory _name, uint256 _expiresAt) external view returns (string memory);
  function getImage(string memory _name, uint256 _expiresAt) external view returns (string memory);
}