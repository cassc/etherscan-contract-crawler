// SPDX-License-Identifier: MIT

// IRewardProgram.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2023 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

interface IRewardProgram {
  /* admin events */
  event RewardProgramFunded(uint256 amount);
  event RewardProgramOutOfFunds();

  /* user events */
  event RewardsClaimed(address indexed contractAddress, uint256 tokenId, address indexed receiver, uint256 rewarded, uint256 remaining);

  event AssetRegistered(address indexed contractAddress, uint256 tokenId, string walletManagerId, uint256 principalAmount);
  event AssetDeposit(address indexed contractAddress, uint256 tokenId, string walletManagerId, uint256 principalAmount);
  event AssetRelease(address indexed contractAddress, uint256 tokenId, uint256 interestAmount);

  /* data types */
  struct ProgramRewardData {
    address stakingToken;
    address rewardToken;
    uint256 baseMultiplier; // Basis Points
  }

  struct AssetStake {
    uint256 start;
    uint256 claimableRewards;
    string walletManagerId;
  }

  function initialize(address stakingToken, address rewardToken, uint256 baseMultiplier, address chargedManagers, address universe, address owner) external;

  /* user functions */
  function getProgramData() external view returns (ProgramRewardData memory programData);
  function getAssetStake(uint256 uuid) external view returns (AssetStake memory);
  function getFundBalance() external view returns (uint256);
  function calculateRewardsEarned(uint256 parentNftUuid, uint256 interestAmount) external view returns (uint256);
  function getClaimableRewards(address contractAddress, uint256 tokenId) external view returns (uint256);

  function registerExistingDeposits(address contractAddress, uint256 tokenId, string calldata walletManagerId) external;
  function registerAssetDeposit(address contractAddress, uint256 tokenId, string calldata walletManagerId, uint256 principalAmount) external;
  function registerAssetRelease(address contractAddress, uint256 tokenId, uint256 interestAmount) external returns (uint256 rewards);
}