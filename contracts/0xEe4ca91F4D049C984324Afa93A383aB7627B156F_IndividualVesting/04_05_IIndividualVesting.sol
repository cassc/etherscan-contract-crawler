//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

interface IIndividualVesting {
  function initialize(
    address _receiverAddress,
    uint256 _grantedAmount,
    uint256 _withdrawnAmount
  ) external;

  function unlockedAmount() external view returns (uint256);

  function withdraw() external;
}