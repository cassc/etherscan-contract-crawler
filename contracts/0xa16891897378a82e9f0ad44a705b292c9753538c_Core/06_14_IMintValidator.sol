// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMintValidator {
  function validate(
    address _recipient,
    uint256 _dropId,
    uint256[] memory _requestedQty,
    string calldata _metadata,
    bytes memory _data
  ) external;
}