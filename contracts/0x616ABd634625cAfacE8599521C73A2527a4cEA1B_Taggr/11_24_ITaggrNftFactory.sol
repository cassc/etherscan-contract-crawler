// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface ITaggrNftFactory {
  function deploy(
    address owner,
    address distributor,
    string memory name,
    string memory symbol,
    string memory baseTokenUri,
    uint256 maxSupply,
    uint96 royaltiesPct
  ) external returns (address);
}