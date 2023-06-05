// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Token {
  function initialize(
    string memory _name,
    string memory _symbol,
    string memory contractURI_,
    string memory tokenURI_,
    address _owner,
    address _trustedAddress,
    uint256 _maxSupply
  ) external;
}