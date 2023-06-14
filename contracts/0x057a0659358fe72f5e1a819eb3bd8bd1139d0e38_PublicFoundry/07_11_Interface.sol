// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface FoundryValidatorInterface {
  function validate(uint256 id, string calldata label)
    external
    view
    returns (bool);
}