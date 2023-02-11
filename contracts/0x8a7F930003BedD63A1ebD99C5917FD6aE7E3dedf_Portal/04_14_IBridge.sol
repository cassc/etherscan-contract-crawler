// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IBridge {
  function transmitRequestV2(
    bytes memory _callData,
    address _receiveSide,
    address _oppositeBridge,
    uint256 _chainId
  ) external;
  
  function receiveRequestV2(
    bytes memory _callData,
    address _receiveSide
  ) external;
}