// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOpenseaStandard {
  function tokenURI(uint256 tokenId) external virtual view returns(string memory);
  function contractURI() external virtual view returns(string memory);
  function setContractURI(string memory _contractURI) external virtual;
}