// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "./Staking.sol";

contract NftStaking is Staking, IERC721ReceiverUpgradeable {

  uint8 public constant BARRACKS = 3;

  IERC721EnumerableUpgradeable public nft;

  mapping(address => uint256[]) public stakedNfts;

  event Staked(address indexed user, uint256[] ids);
  event Unstaked(address indexed user, uint256[] ids);

  function initialize(Village _village, address nftAddress) virtual public initializer {
    super.initialize(_village);
    nft = IERC721EnumerableUpgradeable(nftAddress);
  }

  function onERC721Received(address, address, uint256, bytes calldata) pure external override returns (bytes4) {
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }

  function stake(uint[] memory ids) virtual assertStakesLand(tx.origin) public returns (uint finishTimestamp) {
    uint256 currentStakeId = currentStake[tx.origin];
    if (stakes[currentStakeId + 1].amount != 0) {
      require(stakedNfts[tx.origin].length + ids.length == stakes[currentStakeId + 1].amount, 'You need to stake all the required NFTs');
    }
    if (currentStakeId == 0) {
      firstStake();
    } else {
      if (!currentStakeRewardClaimed[tx.origin]) {
        completeStake();
      }
      assignNextStake(currentStakeId);
    }
    currentStakeStart[tx.origin] = block.timestamp;
    for (uint i = 0; i < ids.length; i++) {
      uint id = ids[i];
      nft.safeTransferFrom(tx.origin, address(this), id);
      stakedNfts[tx.origin].push(id);
    }
    emit Staked(tx.origin, ids);
    return currentStakeStart[tx.origin] + stakes[currentStake[tx.origin]].duration;
  }

  function unstake() virtual public returns (bool stakeCompleted) {
    require(currentStake[tx.origin] != 0, 'You have no stakes to unstake');
    if (canCompleteStake()) {
      completeStake();
      stakeCompleted = true;
    }
    currentStake[tx.origin] = 0;
    currentStakeStart[tx.origin] = 0;
    for (uint i = 0; i < stakedNfts[tx.origin].length; i++) {
      uint256 id = stakedNfts[tx.origin][i];
      nft.safeTransferFrom(address(this), tx.origin, id);
    }
    emit Unstaked(tx.origin, stakedNfts[tx.origin]);
    delete stakedNfts[tx.origin];
  }

  // VIEWS

  function getRequiredStakeAmount() external view returns (uint256) {
    return stakes[currentStake[tx.origin] + 1].amount - getStakedAmount(tx.origin);
  }

  function getStakedAmount(address user) public view returns (uint256) {
    return stakedNfts[user].length;
  }

  // SETTERS

  function setNft(address nftAddress) external restricted {
    nft = IERC721EnumerableUpgradeable(nftAddress);
  }
}