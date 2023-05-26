// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IEvolutionContract {
  function isEvolvingActive() external view returns (bool);
  function isEvolutionValid(uint256[3] memory _tokensToBurn) external returns (bool);
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function getEvolutionPrice() external view returns (uint256);
}