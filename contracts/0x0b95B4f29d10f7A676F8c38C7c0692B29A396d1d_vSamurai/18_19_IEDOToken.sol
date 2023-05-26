// SPDX-License-Identifier: MIT
// BuildingIdeas.io (IEDOToken.sol)

pragma solidity ^0.8.11;

interface IEDOToken {
  event RewardClaimed(address indexed from, uint256 reward);

  function getTotalClaimable(address _from, uint256 _tokenId) external view returns(uint256);
  function updateReward(address _from, address _to, uint256 _tokenId) external;
  function getReward(address _from, uint256 _tokenId) external;
  function burn(address _from, uint256 _amount) external;
}