// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./IBreedCert.sol";

interface INST is IBreedCert {
  event RewardClaimed(address indexed from, uint256 reward);

  function getTotalClaimable(address _from, uint256 _tokenId) external view returns(uint256);
  function updateReward(address _from, address _to, uint256 _tokenId) external;
  function burn(address _from, uint256 _amount) external;
  function getTokenCert(uint256 _tokenId) external view returns(C memory);
}