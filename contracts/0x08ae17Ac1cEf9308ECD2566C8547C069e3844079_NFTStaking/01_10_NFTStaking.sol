// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTStaking is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  // Interfaces for ERC20
  IERC20 public immutable rewardsToken;
  address constant ANTHROCollection = 0xeE5f115811d18a1c5D95457c83ba531Ce0c92f06;
  address constant HUMANCollection = 0xa5c5198c6CE1611f1e998cf681450F8b9E599255;
  address constant HUMANMUSICCollection = 0x021CD12F07d12B1fe1E53B057e1D38553bCc4D72;

  // Staker info
  struct Staker {
    // Amount of ERC721 Tokens staked
    uint256 amountStaked;
    // Last time of details update for this User
    uint256 timeOfLastUpdate;
    // Calculated, but unclaimed rewards for the User. The rewards are
    // calculated each time the user writes to the Smart Contract
    uint256 unclaimedRewards;
  }
   // Stake item
  struct StakeItem {
    uint256 pid;
    uint256[] tokenIds;
  }
  //Vault tokens
  struct VaultInfo {
    IERC721 nft;
    string name;
    mapping(uint256 => address) stakerAddress;
  }

  VaultInfo[] public vaultInfo;

  // Rewards per hour per token deposited in wei.
  // Rewards are cumulated once every hour.
  // uint256 private rewardsPerDay 100 tokens;
  uint256 private rewardsPerDay = 100000000000000000000;

  // Mapping of User Address to Staker info
  mapping(address => Staker) public stakers;
  // Mapping of Token Id to staker. Made for the SC to remeber
  // who to send back the ERC721 Token to.

  address[] public stakersArray;

  // Constructor function
  constructor(IERC20 _rewardsToken) {
    rewardsToken = _rewardsToken;
    addVault(address(ANTHROCollection), "Singularity 0 Universe ANTHRO");
    addVault(address(HUMANCollection), "Singularity 0 Universe HUMAN");
    addVault(address(HUMANMUSICCollection), "Singularity 0 Universe HUMAN MUSIC");
  }

  function addVault(
    address _nft,
    string memory _name
  ) public onlyOwner {
    VaultInfo storage newVaultInfo = vaultInfo.push();
    newVaultInfo.nft = IERC721(_nft);
    newVaultInfo.name = _name;
  }

  // If address already has ERC721 Token/s staked, calculate the rewards.
  // For every new Token Id in param transferFrom user to this Smart Contract,
  // increment the amountStaked and map _msgSender() to the Token Id of the staked
  // Token to later send back on withdrawal. Finally give timeOfLastUpdate the
  // value of now.
  function stake(StakeItem[] calldata _stakeItems) external nonReentrant {
    uint256 length = _stakeItems.length;
    for (uint256 k; k < length; ++k) {
      uint256 _pid = _stakeItems[k].pid;
      uint256[] calldata _tokenIds = _stakeItems[k].tokenIds;
      if (stakers[_msgSender()].amountStaked > 0) {
        uint256 rewards = calculateRewards(_msgSender());
        stakers[_msgSender()].unclaimedRewards += rewards;
      } else {
        stakersArray.push(_msgSender());
      }
      uint256 len = _tokenIds.length;
      for (uint256 i; i < len; ++i) {
        require(
          vaultInfo[_pid].nft.ownerOf(_tokenIds[i]) == _msgSender(),
          "Can't stake tokens you don't own!"
        );
        require(
          vaultInfo[_pid].nft.isApprovedForAll(_msgSender(), address(this)),
          "Can't stake tokens without approved"
        );
        vaultInfo[_pid].nft.transferFrom(_msgSender(), address(this), _tokenIds[i]);
        vaultInfo[_pid].stakerAddress[_tokenIds[i]] = _msgSender();
      }
      stakers[_msgSender()].amountStaked += len;
      stakers[_msgSender()].timeOfLastUpdate = block.timestamp;
    }
  }

  // Calculate rewards for the _msgSender(), check if there are any rewards
  // claim, set unclaimedRewards to 0 and transfer the ERC20 Reward token
  // to the user.
  function claimRewards() public {
    uint256 rewards = calculateRewards(_msgSender()) +
      stakers[_msgSender()].unclaimedRewards;
    require(rewards > 0, "You have no rewards to claim");
    stakers[_msgSender()].timeOfLastUpdate = block.timestamp;
    stakers[_msgSender()].unclaimedRewards = 0;
    rewardsToken.safeTransfer(_msgSender(), rewards);
  }

  // Check if user has any ERC721 Tokens Staked and if he tried to withdraw,
  // calculate the rewards and store them in the unclaimedRewards and for each
  // ERC721 Token in param: check if _msgSender() is the original staker, decrement
  // the amountStaked of the user and transfer the ERC721 token back to them
  function withdraw(StakeItem[] calldata _stakeItems) external nonReentrant {
    require(
      stakers[_msgSender()].amountStaked > 0,
      "You have no tokens staked"
    );

    uint256 length = _stakeItems.length;
    for (uint256 k; k < length; ++k) {
      uint256 _pid = _stakeItems[k].pid;
      uint256[] calldata _tokenIds = _stakeItems[k].tokenIds;

      uint256 rewards = calculateRewards(_msgSender());
      stakers[_msgSender()].unclaimedRewards += rewards;
      uint256 len = _tokenIds.length;
      for (uint256 i; i < len; ++i) {
        require(vaultInfo[_pid].stakerAddress[_tokenIds[i]] == _msgSender());
        vaultInfo[_pid].stakerAddress[_tokenIds[i]] = address(0);
        vaultInfo[_pid].nft.transferFrom(address(this), _msgSender(), _tokenIds[i]);
      }
      stakers[_msgSender()].amountStaked -= len;
      stakers[_msgSender()].timeOfLastUpdate = block.timestamp;
      if (stakers[_msgSender()].amountStaked == 0) {
        for (uint256 j; j < stakersArray.length; ++j) {
          if (stakersArray[j] == _msgSender()) {
            stakersArray[j] = stakersArray[stakersArray.length - 1];
            stakersArray.pop();
          }
        }
      }
    }
  }

  function withdrawAndClaimRewards(StakeItem[] calldata _stakeItems) external nonReentrant {
    require(
      stakers[_msgSender()].amountStaked > 0,
      "You have no tokens staked"
    );

    claimRewards();

    uint256 length = _stakeItems.length;
    for (uint256 k; k < length; ++k) {
      uint256 _pid = _stakeItems[k].pid;
      uint256[] calldata _tokenIds = _stakeItems[k].tokenIds;

      uint256 len = _tokenIds.length;
      for (uint256 i; i < len; ++i) {
        require(vaultInfo[_pid].stakerAddress[_tokenIds[i]] == _msgSender());
        vaultInfo[_pid].stakerAddress[_tokenIds[i]] = address(0);
        vaultInfo[_pid].nft.transferFrom(address(this), _msgSender(), _tokenIds[i]);
      }
      stakers[_msgSender()].amountStaked -= len;
      if (stakers[_msgSender()].amountStaked == 0) {
        for (uint256 j; j < stakersArray.length; ++j) {
          if (stakersArray[j] == _msgSender()) {
            stakersArray[j] = stakersArray[stakersArray.length - 1];
            stakersArray.pop();
          }
        }
      }
    }
  }
  // Set the rewardsPerDay variable
  // Because the rewards are calculated passively, the owner has to first update the rewards
  // to all the stakers, witch could result in very heavy load and expensive transactions or
  // even reverting due to reaching the gas limit per block. Redesign incoming to bound loop.
  function setRewardsPerHour(uint256 _newValue) public onlyOwner {
    address[] memory _stakers = stakersArray;
    uint256 len = _stakers.length;
    for (uint256 i; i < len; ++i) {
      address user = _stakers[i];
      stakers[user].unclaimedRewards += calculateRewards(user);
      stakers[_msgSender()].timeOfLastUpdate = block.timestamp;
    }
    rewardsPerDay = _newValue;
  }

  //////////
  // View //
  //////////

  function userStakeInfo(address _user)
    public
    view
    returns (uint256 _tokensStaked, uint256 _availableRewards)
  {
    return (stakers[_user].amountStaked, availableRewards(_user));
  }

  function tokensOfOwner(address _user, uint256 _pid)
    public
    view
    returns (uint256[] memory tokenIds)
  {
    uint256 index = 0;
    uint256 length = 3333;
    uint256[] memory tmp = new uint256[](length);

    for (uint256 k; k <= length; ++k) {
      if (vaultInfo[_pid].stakerAddress[k] == _user) {
        tmp[index] = k;
        index +=1;
      }
    }

    uint256[] memory stakedIds = new uint256[](index);
    for(uint i = 0; i < index; i++) {
      stakedIds[i] = tmp[i];
    }

    return stakedIds;
  }

  function availableRewards(address _user) internal view returns (uint256) {
    if (stakers[_user].amountStaked == 0) {
      return stakers[_user].unclaimedRewards;
    }
    uint256 _rewards = stakers[_user].unclaimedRewards +
      calculateRewards(_user);
    return _rewards;
  }

  /////////////
  // Internal//
  /////////////

  // Calculate rewards for param _staker by calculating the time passed
  // since last update in hours and mulitplying it to ERC721 Tokens Staked
  // and rewardsPerDay.
  function calculateRewards(address _staker)
    internal
    view
    returns (uint256 _rewards)
  {
    Staker memory staker = stakers[_staker];
    return (((
        ((block.timestamp - staker.timeOfLastUpdate) * staker.amountStaked)
    ) * rewardsPerDay) / 86400);
  }
}