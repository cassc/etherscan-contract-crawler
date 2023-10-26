// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQueryDataStorage {
  function storeData(bytes memory _queryData) external; 
  function getQueryData(bytes32 _queryId) external view returns (bytes memory);
}