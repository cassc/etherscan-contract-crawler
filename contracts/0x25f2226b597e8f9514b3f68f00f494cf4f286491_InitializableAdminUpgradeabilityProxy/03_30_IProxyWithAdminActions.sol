// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IProxyWithAdminActions {
  function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
  function changeAdmin(address newAdmin) external;
}