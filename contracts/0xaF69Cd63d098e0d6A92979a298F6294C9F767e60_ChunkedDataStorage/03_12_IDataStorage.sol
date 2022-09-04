// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface IDataStorage is IERC165 {
  function indexToData(uint256 index) external view returns (bytes memory);
}