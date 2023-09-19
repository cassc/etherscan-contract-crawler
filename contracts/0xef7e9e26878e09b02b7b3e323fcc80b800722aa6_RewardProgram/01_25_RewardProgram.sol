// SPDX-License-Identifier: MIT

// RewardProgram.sol -- Part of the Charged Particles Protocol
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

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IRewardProgram.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "../interfaces/IUniverseRP.sol";
import "../interfaces/IChargedManagers.sol";
import "../interfaces/IWalletManager.sol";
import "../lib/TokenInfo.sol";
import "../lib/ReentrancyGuard.sol";
import "../lib/BlackholePrevention.sol";
import "../interfaces/IERC20Detailed.sol";

contract RewardProgram is
  IRewardProgram,
  BlackholePrevention,
  IERC165,
  ReentrancyGuard,
  IERC721Receiver,
  IERC1155Receiver
{
  using SafeMath for uint256;
  using TokenInfo for address;
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.UintSet;

  uint256 constant private PERCENTAGE_SCALE = 1e4; // 10000 (100%)
  uint256 constant private LEPTON_MULTIPLIER_SCALE = 1e2;

  address private _owner;
  IUniverseRP private _universe;
  IChargedManagers private _chargedManagers;
  ProgramRewardData private _programData;
  mapping(uint256 => AssetStake) private _assetStake;


  /***********************************|
  |          Initialization           |
  |__________________________________*/

  constructor() public {}

  function initialize(
    address stakingToken,
    address rewardToken,
    uint256 baseMultiplier,
    address chargedManagers,
    address universe,
    address owner
  ) external override {
    require(_owner == address(0x0), "Already initialized");
    _owner = owner;

    // Prepare Reward Program
    _programData.stakingToken = stakingToken;
    _programData.rewardToken = rewardToken;
    _programData.baseMultiplier = baseMultiplier; // Basis Points

    // Connect to Charged Particles
    _chargedManagers = IChargedManagers(chargedManagers);
    _universe = IUniverseRP(universe);
  }


  /***********************************|
  |         Public Functions          |
  |__________________________________*/

  function getProgramData() external view override returns (ProgramRewardData memory) {
    return _programData;
  }

  function getAssetStake(uint256 parentNftUuid) external view override returns (AssetStake memory) {
    return _assetStake[parentNftUuid];
  }

  function getFundBalance() external view override returns (uint256) {
    return _getFundBalance();
  }

  function calculateRewardsEarned(uint256 parentNftUuid, uint256 interestAmount) public view override returns (uint256) {
    return _calculateRewardsEarned(parentNftUuid, interestAmount);
  }

  function getClaimableRewards(address contractAddress, uint256 tokenId) external view override returns (uint256) {
    uint256 parentNftUuid = contractAddress.getTokenUUID(tokenId);
    return _assetStake[parentNftUuid].claimableRewards;
  }

  function onERC721Received(address, address, uint256, bytes calldata) external override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  function onERC1155Received(address, address, uint256, uint256, bytes calldata) external override returns (bytes4) {
    return IERC1155Receiver.onERC1155BatchReceived.selector;
  }

  function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external override returns (bytes4) {
    return "";
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165)
    returns (bool)
  {
    // default interface support
    if (
      interfaceId == type(IERC721Receiver).interfaceId ||
      interfaceId == type(IERC1155Receiver).interfaceId ||
      interfaceId == type(IERC165).interfaceId
    ) {
      return true;
    }
  }

  function owner() public view returns (address) {
    return _owner;
  }


  /***********************************|
  |          Only Universe            |
  |__________________________________*/

  function registerAssetDeposit(
    address contractAddress,
    uint256 tokenId,
    string calldata walletManagerId,
    uint256 principalAmount
  )
    external
    override
    onlyUniverse
  {
    uint256 parentNftUuid = contractAddress.getTokenUUID(tokenId);
    AssetStake storage assetStake = _assetStake[parentNftUuid];

    if (assetStake.start == 0) {
      assetStake.start = block.number;
      assetStake.walletManagerId = walletManagerId;
    }
    emit AssetDeposit(contractAddress, tokenId, walletManagerId, principalAmount);
  }

  function registerAssetRelease(
    address contractAddress,
    uint256 tokenId,
    uint256 interestAmount
  )
    external
    override
    onlyUniverse
    nonReentrant
    returns (uint256 rewards)
  {
    uint256 parentNftUuid = contractAddress.getTokenUUID(tokenId);
    AssetStake storage assetStake = _assetStake[parentNftUuid];

    // Update Claimable Rewards
    uint256 newRewards = _calculateRewardsEarned(parentNftUuid, interestAmount);
    assetStake.claimableRewards = assetStake.claimableRewards.add(newRewards);

    // Reset Stake if Principal Balance falls to Zero
    IWalletManager walletMgr = _chargedManagers.getWalletManager(assetStake.walletManagerId);
    uint256 principal = walletMgr.getPrincipal(contractAddress, tokenId, _programData.stakingToken);
    if (principal == 0) {
      assetStake.start = 0;
    }

    // Issue Rewards to NFT Owner
    rewards = _claimRewards(contractAddress, tokenId);

    emit AssetRelease(contractAddress, tokenId, interestAmount);
  }


  /***********************************|
  |         Reward Calculation        |
  |__________________________________*/

  function _calculateRewardsEarned(uint256 parentNftUuid, uint256 interestAmount) internal view returns (uint256 totalReward) {
    uint256 baseReward = _calculateBaseReward(interestAmount);
    uint256 leptonMultipliedReward = _calculateMultipliedReward(parentNftUuid, baseReward);
    totalReward = _convertDecimals(leptonMultipliedReward);
  }

  function _calculateBaseReward(uint256 amount) internal view returns(uint256 baseReward) {
    baseReward = amount.mul(_programData.baseMultiplier).div(PERCENTAGE_SCALE);
  }

  function _calculateMultipliedReward(uint256 parentNftUuid, uint256 baseReward) internal view returns(uint256) {
    AssetStake storage assetStake = _assetStake[parentNftUuid];
    if (assetStake.start == 0) { return baseReward; }

    IUniverseRP.NftStake memory nftStake = _universe.getNftStake(parentNftUuid);
    uint256 multiplierBP = nftStake.multiplier;

    uint256 assetDepositLength = block.number.sub(assetStake.start);
    uint256 nftDepositLength = 0;
    if (nftStake.releaseBlockNumber > 0) {
      nftDepositLength = nftStake.releaseBlockNumber.sub(nftStake.depositBlockNumber);
    } else {
      nftDepositLength = block.number.sub(nftStake.depositBlockNumber);
    }

    if (multiplierBP == 0 || nftDepositLength == 0 || assetDepositLength == 0) {
      return baseReward;
    }

    if (nftDepositLength > assetDepositLength) {
      nftDepositLength = assetDepositLength;
    }

    // Percentage of the total program that the Multiplier Nft was deposited for
    uint256 nftRewardRatioBP = nftDepositLength.mul(PERCENTAGE_SCALE).div(assetDepositLength);

    // Amount of reward that the Multiplier Nft is responsible for
    uint256 amountGeneratedDuringNftDeposit = baseReward.mul(nftRewardRatioBP).div(PERCENTAGE_SCALE);

    // Amount of Multiplied Reward from NFT
    uint256 multipliedReward = amountGeneratedDuringNftDeposit.mul(multiplierBP.mul(LEPTON_MULTIPLIER_SCALE)).div(PERCENTAGE_SCALE);

    // Amount of Base Reward without Multiplied NFT Rewards
    uint256 amountGeneratedWithoutNftDeposit = baseReward.sub(amountGeneratedDuringNftDeposit);

    // Amount of Base Rewards + Multiplied NFT Rewards
    return amountGeneratedWithoutNftDeposit.add(multipliedReward);
  }


  /***********************************|
  |          Only Admin/DAO           |
  |__________________________________*/

  function fundProgram(uint256 amount) external onlyOwner {
    require(_programData.rewardToken != address(0), "RP:E-405");
    IERC20(_programData.rewardToken).safeTransferFrom(msg.sender, address(this), amount);
    emit RewardProgramFunded(amount);
  }

  function setStakingToken(address newStakingToken) external onlyOwner {
    _programData.stakingToken = newStakingToken;
  }

  function setRewardToken(address newRewardToken) external onlyOwner {
    _programData.rewardToken = newRewardToken;
  }

  function setBaseMultiplier(uint256 newMultiplier) external onlyOwner {
    _programData.baseMultiplier = newMultiplier; // Basis Points
  }

  function setChargedManagers(address manager) external onlyOwner {
    _chargedManagers = IChargedManagers(manager);
  }

  function setUniverse(address universe) external onlyOwner {
    _universe = IUniverseRP(universe);
  }

  function registerExistingDeposits(address contractAddress, uint256 tokenId, string calldata walletManagerId) external override onlyOwner {
    uint256 parentNftUuid = contractAddress.getTokenUUID(tokenId);

    // Initiate Asset Stake
    IWalletManager walletMgr = _chargedManagers.getWalletManager(walletManagerId);
    uint256 principal = walletMgr.getPrincipal(contractAddress, tokenId, _programData.stakingToken);
    if (principal > 0) {
      _assetStake[parentNftUuid] = AssetStake(block.number, 0, walletManagerId);
      emit AssetRegistered(contractAddress, tokenId, walletManagerId, principal);
    }
  }


  /***********************************|
  |          Only Admin/DAO           |
  |      (blackhole prevention)       |
  |__________________________________*/

  function withdrawEther(address payable receiver, uint256 amount) external onlyOwner {
    _withdrawEther(receiver, amount);
  }

  function withdrawErc20(address payable receiver, address tokenAddress, uint256 amount) external onlyOwner {
    _withdrawERC20(receiver, tokenAddress, amount);
  }

  function withdrawERC721(address payable receiver, address tokenAddress, uint256 tokenId) external onlyOwner {
    _withdrawERC721(receiver, tokenAddress, tokenId);
  }

  function withdrawERC1155(address payable receiver, address tokenAddress, uint256 tokenId, uint256 amount) external onlyOwner {
    _withdrawERC1155(receiver, tokenAddress, tokenId, amount);
  }


  /***********************************|
  |         Private Functions         |
  |__________________________________*/

  function _claimRewards(
    address contractAddress,
    uint256 tokenId
  )
    internal
    returns (uint256 totalReward)
  {
    uint256 parentNftUuid = contractAddress.getTokenUUID(tokenId);
    AssetStake storage assetStake = _assetStake[parentNftUuid];

    // Rewards Receiver
    address receiver = IERC721(contractAddress).ownerOf(tokenId);

    // Ensure Reward Pool has Sufficient Balance
    totalReward = assetStake.claimableRewards;
    uint256 fundBalance = _getFundBalance();
    uint256 unavailReward = totalReward > fundBalance ? totalReward.sub(fundBalance) : 0;

    // Determine amount of Rewards to Transfer
    if (unavailReward > 0) {
      totalReward = totalReward.sub(unavailReward);
      emit RewardProgramOutOfFunds();
    }

    // Update Asset Stake
    assetStake.claimableRewards = unavailReward;

    if (totalReward > 0) {
      // Transfer Available Rewards to Receiver
      IERC20(_programData.rewardToken).safeTransfer(receiver, totalReward);
    }

    emit RewardsClaimed(contractAddress, tokenId, receiver, totalReward, unavailReward);
  }

  function _convertDecimals(uint256 reward) internal view returns (uint256) {
    uint8 stakingTokenDecimals = IERC20Detailed(_programData.stakingToken).decimals();
    return reward.mul(10**(18 - uint256(stakingTokenDecimals)));
  }

  function _getFundBalance() internal view returns (uint256) {
    return IERC20Detailed(_programData.rewardToken).balanceOf(address(this));
  }


  modifier onlyOwner() {
    require(_owner == msg.sender, "Caller is not the owner");
    _;
  }

  modifier onlyUniverse() {
    require(msg.sender == address(_universe), "RP:E-108");
    _;
  }
}