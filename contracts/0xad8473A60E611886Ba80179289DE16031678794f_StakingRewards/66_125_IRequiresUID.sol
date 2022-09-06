// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IRequiresUID {
  function hasAllowedUID(address sender) external view returns (bool);
}