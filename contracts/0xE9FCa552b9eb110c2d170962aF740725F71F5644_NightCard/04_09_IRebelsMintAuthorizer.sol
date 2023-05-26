// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRebelsMintAuthorizer {
  function authorizeMint(
    address sender,
    uint256 value,
    uint256 number,
    bytes32[] memory senderData
  ) external;
}