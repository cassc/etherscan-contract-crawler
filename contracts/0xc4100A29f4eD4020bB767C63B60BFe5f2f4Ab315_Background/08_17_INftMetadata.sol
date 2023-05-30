//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface INftMetadata {
  function renderTokenByIdBack(uint256 id) external view returns (string memory);
  function renderTokenByIdFront(uint256 id) external view returns (string memory);
  function renderTokenById(uint256 id) external view returns (string memory);
  function getTraits(uint256 id) external view returns(string memory);
  function tokenURI(uint256 id) external view returns (string memory); 
}