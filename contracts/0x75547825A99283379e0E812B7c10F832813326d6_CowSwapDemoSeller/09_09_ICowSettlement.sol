// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;


interface ICowSettlement {
  function setPreSignature(bytes calldata orderUid, bool signed) external;
  function preSignature(bytes calldata orderUid) external view returns (uint256);
  function domainSeparator() external view returns (bytes32);
}