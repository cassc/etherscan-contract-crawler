// SPDX-Licence-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IBorrower {
  function initialize(address owner, address _config) external;
}