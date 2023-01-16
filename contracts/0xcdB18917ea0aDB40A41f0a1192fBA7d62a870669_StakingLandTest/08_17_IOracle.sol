// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracle {
    function createRequest (
    string memory _urlToQuery,
    string memory _attributeToFetch,
    address callbackAddress,
    string memory sign
  ) external;
}