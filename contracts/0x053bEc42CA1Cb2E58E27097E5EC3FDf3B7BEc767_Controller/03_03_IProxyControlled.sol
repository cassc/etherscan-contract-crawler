// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IProxyControlled {

  function initProxy(address _logic) external;

  function upgrade(address _newImplementation) external;

  function implementation() external returns (address);

}