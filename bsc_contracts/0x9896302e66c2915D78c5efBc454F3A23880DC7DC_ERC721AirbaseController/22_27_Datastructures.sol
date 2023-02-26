//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

library Datastructures {
  struct CertificateInfo {
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }
}