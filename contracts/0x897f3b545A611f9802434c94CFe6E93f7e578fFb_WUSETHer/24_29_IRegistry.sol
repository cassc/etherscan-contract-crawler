// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;


interface IRegistry
{
  function get (string calldata id) external view returns (address);


  function provisioner () external view returns (address);

  function frontender () external view returns (address);

  function collector () external view returns (address);
}