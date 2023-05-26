//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./INftStaking.sol";

contract NftStaking is INftStaking, IERC721Receiver, AccessControl {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;

  IERC20 private rewardToken;

  mapping(PlanId => Plan) private plans;
  EnumerableSet.AddressSet private whitelistedNFTs;
  mapping(address => RewardPeriod[]) private whitelistedNFTRewards;
  mapping(address => mapping(uint256 => NFTStake)) private stakes;

  mapping(address => mapping(address => EnumerableSet.UintSet))
    private userNFTs;

  uint256 private withdrawTimestamp;

  constructor(IERC20 _rewardToken, address _admin) {
    _initPlans();
    rewardToken = _rewardToken;

    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
  }

  /**
   * @dev Returns all user stakes
   */
  function getUserStakes(address user)
    external
    view
    returns (UserNFTStake[] memory nftStakes)
  {
    uint256 count;

    for (uint256 i = 0; i < whitelistedNFTs.length(); i++) {
      address nftContract = whitelistedNFTs.at(i);
      count += userNFTs[user][nftContract].length();
    }

    nftStakes = new UserNFTStake[](count);
    uint256 stakeIndex;

    for (uint256 i = 0; i < whitelistedNFTs.length(); i++) {
      address nftContract = whitelistedNFTs.at(i);
      for (uint256 j = 0; j < userNFTs[user][nftContract].length(); j++) {
        uint256 tokenId = userNFTs[user][nftContract].at(j);
        NFTStake memory nftStake = stakes[nftContract][tokenId];
        nftStakes[stakeIndex++] = UserNFTStake(
          nftContract,
          tokenId,
          nftStake.planId,
          nftStake.stakedAt,
          nftStake.unstakedAt,
          nftStake.rewardClaimed
        );
      }
    }

    return nftStakes;
  }

  /**
   * @dev Returns all whitelisted contracts and their rewardRates
   */
  function getWhitelistedContracts()
    external
    view
    returns (WhitelistedContract[] memory whitelistedContracts)
  {
    whitelistedContracts = new WhitelistedContract[](whitelistedNFTs.length());

    for (uint256 i = 0; i < whitelistedNFTs.length(); i++) {
      address nftContract = whitelistedNFTs.at(i);
      whitelistedContracts[i] = WhitelistedContract(
        nftContract,
        whitelistedNFTRewards[nftContract]
      );
    }

    return whitelistedContracts;
  }

  /**
   * @dev Allows user to stake multiple nft-s
   */
  function stake(NFTWithPlanId[] calldata nfts) external {
    for (uint256 i = 0; i < nfts.length; i = unsafe_inc(i)) {
      _stake(nfts[i].nftContract, nfts[i].tokenId, nfts[i].planId);
    }
  }

  /**
   * @dev Allows user to check reward for his NFT
   */
  function getReward(NFT calldata nft) external view returns (uint256) {
    return _getReward(nft.nftContract, nft.tokenId);
  }

  /**
   * @dev Allows user to claim rewards for nft-s
   */
  function claimRewards(NFT[] calldata nfts) external {
    for (uint256 i = 0; i < nfts.length; i++) {
      _claimRewards(nfts[i].nftContract, nfts[i].tokenId);
    }
  }

  /**
   * @dev Allows user to claim rewards for nft-s
   */
  function unstake(NFT[] calldata nfts) external {
    for (uint256 i = 0; i < nfts.length; i++) {
      _unstake(nfts[i].nftContract, nfts[i].tokenId);
    }
  }

  /**
   * @dev Allows default admin to set dailyReward for nftContract
   */
  function setDailyReward(address nftContract, uint256 dailyReward)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    whitelistedNFTs.add(nftContract);
    whitelistedNFTRewards[nftContract].push(
      RewardPeriod(dailyReward, block.timestamp)
    );
  }

  /**
   * @dev Allows admin to announce withdraw 30 days before
   */
  function announceWithdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(withdrawTimestamp == 0, "Already announced");

    withdrawTimestamp = block.timestamp + 30 days;
    emit WithdrawAnnounced(withdrawTimestamp);
  }

  /**
   * @dev Allows admin to cancel withdraw announcement
   */
  function cancelWithdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
    withdrawTimestamp = 0;
    emit WithdrawCancelled();
  }

  /**
   * @dev Allows admin to withdraw rewardToken funds 30 days after withdraw announcement
   */
  function withdraw(address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(
      withdrawTimestamp > 0 && withdrawTimestamp < block.timestamp,
      "Can only withdraw 30 days after announcement"
    );

    uint256 amount = rewardToken.balanceOf(address(this));

    rewardToken.safeTransfer(recipient, amount);

    emit Withdrawn(amount);
  }

  // ---------------------------------------------------

  function _stake(
    address nftContract,
    uint256 tokenId,
    PlanId planId
  ) private {
    // check if contract is whitelisted
    require(
      whitelistedNFTs.contains(nftContract),
      "NFT contract not whitelisted"
    );

    // transfer nft here
    IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);

    userNFTs[msg.sender][nftContract].add(tokenId);

    stakes[nftContract][tokenId] = NFTStake(
      msg.sender,
      planId,
      uint64(block.timestamp),
      0,
      0
    );

    emit Staked(msg.sender, planId, nftContract, tokenId);
  }

  function _getReward(address nftContract, uint256 tokenId)
    private
    view
    returns (uint256)
  {
    NFTStake storage nftStake = stakes[nftContract][tokenId];

    RewardPeriod[] memory rewardPeriods = whitelistedNFTRewards[nftContract];

    uint256 reward;

    for (uint256 i = 0; i < rewardPeriods.length; i = unsafe_inc(i)) {
      uint256 startTime = Math.max(
        nftStake.stakedAt,
        rewardPeriods[i].validFrom
      );

      uint256 endTime = i == rewardPeriods.length - 1
        ? block.timestamp
        : rewardPeriods[i + 1].validFrom;

      if (nftStake.unstakedAt > 0) {
        endTime = Math.min(nftStake.unstakedAt, endTime);
      }

      uint256 timeStaked = endTime - startTime;

      reward += ((timeStaked *
        rewardPeriods[i].dailyReward *
        plans[nftStake.planId].dailyRewardPercentage) / 100 days);
    }

    return reward - nftStake.rewardClaimed;
  }

  function _claimRewards(address nftContract, uint256 tokenId) private {
    NFTStake storage nftStake = stakes[nftContract][tokenId];

    require(nftStake.user == msg.sender, "Not owner of this NFT");

    uint256 amount = _getReward(nftContract, tokenId);

    nftStake.rewardClaimed += amount;

    rewardToken.safeTransfer(nftStake.user, amount);

    emit RewardClaimed(
      nftStake.user,
      nftStake.planId,
      nftContract,
      tokenId,
      amount
    );
  }

  function _unstake(address nftContract, uint256 tokenId) private {
    NFTStake storage nftStake = stakes[nftContract][tokenId];

    require(nftStake.user == msg.sender, "Not owner of this NFT");
    require(nftStake.unstakedAt == 0, "NFT already unstaked");
    require(
      nftStake.stakedAt + plans[nftStake.planId].lockDuration < block.timestamp,
      "Cannot unstake yet"
    );

    nftStake.unstakedAt = uint64(block.timestamp);

    userNFTs[msg.sender][nftContract].remove(tokenId);

    // claim rewards
    _claimRewards(nftContract, tokenId);

    // transfer nft back to user
    IERC721(nftContract).safeTransferFrom(
      address(this),
      nftStake.user,
      tokenId
    );

    emit Unstaked(nftStake.user, nftStake.planId, nftContract, tokenId);
  }

  /**
   * @dev Inits the plans
   */
  function _initPlans() private {
    plans[PlanId.plan0monthsLock] = Plan(0, 100);
    plans[PlanId.plan1monthsLock] = Plan(30 days, 115);
    plans[PlanId.plan3monthsLock] = Plan(90 days, 150);
    plans[PlanId.plan6monthsLock] = Plan(180 days, 200);
  }

  /**
   * @dev Allows safe transfers to this contract address
   */
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  /**
   * @dev Spares tiny bit of gas
   */
  function unsafe_inc(uint256 n) private pure returns (uint256) {
    unchecked {
      return n + 1;
    }
  }
}