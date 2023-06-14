// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface FoundryGuardInterface {
  function authorize(
    uint256 id,
    address wallet,
    string calldata label,
    bytes calldata credentials
  ) external view returns (bool);
}