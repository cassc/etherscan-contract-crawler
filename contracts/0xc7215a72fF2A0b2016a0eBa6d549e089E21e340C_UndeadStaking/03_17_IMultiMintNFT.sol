// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IMultiMintNFT {
  function multipleMint(
    address toAddr,
    uint256 from,
    uint256 to,
    uint256 pkgId
  ) external;
}