// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ILido {
  function submit(address _referral) external payable returns (uint256 shares);

  function sharesOf(address _account) external view returns (uint256);

  function transferShares(address _recipient, uint256 _sharesAmount) external returns (uint256 tokens);
}