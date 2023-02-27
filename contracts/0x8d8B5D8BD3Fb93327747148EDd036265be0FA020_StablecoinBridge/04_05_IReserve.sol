// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReserve {
   function isQualified(address sender, address[] calldata helpers) external view returns (bool);
}