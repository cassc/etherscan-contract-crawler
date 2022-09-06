// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IRandomNumberConsumer {

  function getRandomNumber() external returns (bytes32 requestId);
  function readFulfilledRandomness(bytes32 requestId) external view returns (uint256);
  function setRandomnessRequesterApproval(address _requester, bool _approvalStatus) external;

}