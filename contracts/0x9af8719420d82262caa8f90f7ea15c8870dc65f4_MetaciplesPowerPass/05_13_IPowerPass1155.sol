// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPowerPass1155{
  function burnFrom( uint id, uint quantity, address account ) external payable;
}