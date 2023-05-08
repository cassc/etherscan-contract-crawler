// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct QRNGStorage {
  address airnodeRrp;
  address airnode;
  bytes32 endpointIdUint256;
  address sponsorWallet;
  mapping(bytes32 => bool) expectingRequestWithIdToBeFulfilled;
}