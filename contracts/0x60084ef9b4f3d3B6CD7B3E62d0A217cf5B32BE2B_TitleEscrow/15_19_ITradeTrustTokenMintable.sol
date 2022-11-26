// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ITradeTrustTokenMintable {
  function mint(
    address beneficiary,
    address holder,
    uint256 tokenId
  ) external returns (address);
}