// SPDX-License-Identifier: MIT

// IUniverseRP.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
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

import "./IUniverse.sol";

/**
 * @title Universal Controller interface for Rewards Program
 * @dev ...
 */
interface IUniverseRP is IUniverse {
  event RewardProgramSet(address indexed assetToken, address indexed rewardProgram);
  event RewardProgramRemoved(address indexed assetToken);
  event NftDeposit(address indexed contractAddress, uint256 tokenId, address indexed nftTokenAddress, uint256 nftTokenId);
  event NftRelease(address indexed contractAddress, uint256 tokenId, address indexed nftTokenAddress, uint256 nftTokenId);

  struct NftStake {
    uint256 multiplier; // in Basis Points
    uint256 depositBlockNumber;
    uint256 releaseBlockNumber;
  }

  function getRewardProgram(address asset) external view returns (address);
  function getNftStake(uint256 uuid) external view returns (NftStake memory);
}