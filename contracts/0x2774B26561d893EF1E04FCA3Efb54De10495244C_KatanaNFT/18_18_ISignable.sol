// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISignable {
  function uniq() external view returns (bytes32);

  function signer() external view returns (address);
}