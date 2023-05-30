// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


interface IRegistry
{
  function get (string calldata name) external view returns (address);


  function provisioner () external view returns (address);

  function frontender () external view returns (address);

  function collector () external view returns (address);
}