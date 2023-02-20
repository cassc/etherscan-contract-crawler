// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ISLERC721ATransferAuthorizer {
  function isERC721ATransferAuthorized(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) external view returns (bool);
}