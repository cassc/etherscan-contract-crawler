// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;


interface IERC721Deterministic {
  function issueToken(address _beneficiary, uint256 _optionId, uint256 _issuedId) external;
}