// SPDX-License-Identifier: MIT
// EPS Contracts v2.0.0
// www.eternalproxy.com

/**
 
@dev IERCOmnReceiver - Interface

 */

pragma solidity ^0.8.15;

interface IERCOmnReceiver {
  function onTokenTransfer(
    address sender,
    uint256 value,
    bytes memory data
  ) external payable;
}