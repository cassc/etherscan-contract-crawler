// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IProxyBotChecker {
  function getVaultAddressForDelegate(address delegateAddress) external view returns (address);
}