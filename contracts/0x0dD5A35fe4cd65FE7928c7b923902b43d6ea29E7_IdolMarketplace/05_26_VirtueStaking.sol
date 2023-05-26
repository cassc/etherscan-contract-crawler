// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "./VirtueToken.sol";
import "./interface/IRewards.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
  @notice VirtueStaking is a contract that holds the functionality for staking and claiming VIRTUE
    rewards. It is inherited by the IdolMarketplace, which takes a commission on God NFT sales and
    distributes the commission to the stakers of the VIRTUE token.
*/
contract VirtueStaking is ReentrancyGuard, Ownable {
  // mintContractAddress holds a reference to the address of the minting contract.
  address public immutable mintContractAddress;

  // virtueToken holds a reference to the VirtueToken ERC20 contract.
  VirtueToken public virtueToken;

  // cumulativeETH represents the cumulative amount of rewards that have been earned per staked
  // VIRTUE token since the inception of the protocol. This amount increases whenever
  // distributeRewards is called.
  uint public cumulativeETH;

  // claimedSnapshots is a mapping that stores the amount of ETH that an address is ineligible to
  // claim per VIRTUE token staked. The difference between a user's claimedSnapshot and the current
  // cumulativeETH therefore represents the amount of rewards they are eligible to claim per VIRTUE
  // token staked.
  mapping(address => uint) claimedSnapshots;

  // userStakes tracks how much VIRTUE token a particular address has staked in the protocol.
  mapping(address => uint) userStakes;

  // extraRewards holds the addresses of additional contracts that implement the IRewards interface
  // and provide additional rewards to VIRTUE stakers.
  address[] public extraRewards;

  // DECIMAL_PRECISION is used as a multiplier on cumulativeETH since the ETH/VIRTUE ratio cannot
  // be accurately expressed as a whole integer.
  uint constant DECIMAL_PRECISION = 10**18;

  constructor(address _mintContractAddress, address _virtueTokenAddress)
  {
    cumulativeETH = 0;
    mintContractAddress = _mintContractAddress;
    virtueToken = VirtueToken(_virtueTokenAddress);
  }

  /**
    @notice setVirtueTokenAddr sets the address of the VIRTUE Token ERC20 contract.
    @param _virtueTokenAddr The address of the VIRTUE token contract.
  */
  function setVirtueTokenAddr(address _virtueTokenAddr)
    external
    onlyMintContract
  {
    virtueToken = VirtueToken(_virtueTokenAddr);
  }


  /**
    @notice getTotalVirtueStake returns total amount of VIRTUE Token staked in the protocol.
  */
  function getTotalVirtueStake()
    public
    view
    returns (uint)
  {
    return(virtueToken.balanceOf(address(this)));
  }

  /**
    @notice getUserVirtueStake returns total amount of VIRTUE Token a specific user has staked in the
      protocol.
    @param _user The address of the user to get the stake for.
  */
  function getUserVirtueStake(address _user)
    external
    view
    returns (uint)
  {
    return userStakes[_user];
  }

  /**
    @notice increaseVirtueStake increases a user's VIRTUE stake.
    @param _virtueTokenAmt The amount of VIRTUE to stake on behalf of the user
  */
  function increaseVirtueStake(uint _virtueTokenAmt)
    external
  {
    // Also stake with any linked extraRewards contracts.
    for (uint i = 0; i < extraRewards.length; i++) {
      IRewards(extraRewards[i]).increaseStake(msg.sender, _virtueTokenAmt);
    }

    uint currentStake = userStakes[msg.sender];
    // If the sender has any pending ETH gains from staking, claim them before increasing their stake.
    if (currentStake > 0) {
      claimEthRewards(msg.sender);
    } else {
      claimedSnapshots[msg.sender] = cumulativeETH;
    }
    userStakes[msg.sender] = currentStake + _virtueTokenAmt;
    require(
      virtueToken.transferFrom(msg.sender, address(this), _virtueTokenAmt),
      "Reverting because call to virtueToken.transferFrom returned false"
    );
  }

  /**
    @notice decreaseVirtueStake decreases a user's VIRTUE stake.
    @param _virtueTokenAmt The amount of VIRTUE to unstake on behalf of the user. If this amount exceeds
      the user's current stake, it unstakes their entire stake instead.
  */
  function decreaseVirtueStake(uint _virtueTokenAmt)
    external
  {
    uint currentStake = userStakes[msg.sender];
    require(currentStake > 0, "User must have current stake in order to unstake");

    // Also decrease stake with any linked extraRewards contracts.
    for (uint i = 0; i < extraRewards.length; i++) {
      IRewards(extraRewards[i]).decreaseStake(msg.sender, _virtueTokenAmt);
    }

    // Before unstaking, claim any pending staking gains.
    claimEthRewards(msg.sender);
    if (currentStake <= _virtueTokenAmt) {
      delete(userStakes[msg.sender]);
      delete(claimedSnapshots[msg.sender]);
      console.log("here");
      require(
        virtueToken.transfer(msg.sender, currentStake),
        "Reverting because call to virtueToken.transfer returned false"
      );
    }
    else {
      userStakes[msg.sender] = currentStake - _virtueTokenAmt;
      console.log("there");
      require(
        virtueToken.transfer(msg.sender, _virtueTokenAmt),
        "Reverting because call to virtueToken.transfer returned false"
      );
    }
  }

  /**
    @notice extraRewardsLength returns the length of the extraRewards array.
    @return (uint256) The length of the extraRewards array. Duh.
  */
  function extraRewardsLength() external view returns (uint256) {
    return extraRewards.length;
  }

  /**
    @notice addExtraReward appends a reward contract address to the extraRewards array.
    @param _rewardContractAddress The address of the IRewards contract to add.
  */
  function addExtraReward(address _rewardContractAddress) external onlyOwner {
    extraRewards.push(_rewardContractAddress);
  }

  /**
    @notice clearExtraRewards removes all entries from the extraRewards array.
  */
  function clearExtraRewards() external onlyOwner {
    delete extraRewards;
  }

  /**
    @notice getPendingETHGain returns how much in staking rewards are currently available and
      still unclaimed by the user.
  */
  function getPendingETHGain(address _user)
    public
    view
    returns(uint)
  {
    return (userStakes[_user] * (cumulativeETH - claimedSnapshots[_user]) / DECIMAL_PRECISION);
  }
  /**
    @notice distributeRewards is a payable function that takes ETH from sender and allocates the
      ETH sent as rewards to all current stakers.
  */
  function distributeRewards()
    external
    payable
  {
    _distributeRewards(msg.value);
  }

  /**
    @notice This contract's receive function also calls _distributeRewards if any ETH is sent to
      the contract.
  */
  receive() external payable {
    _distributeRewards(msg.value);
  }

  function _distributeRewards(uint _ethAmt)
    internal
  {
    cumulativeETH = cumulativeETH + (_ethAmt * DECIMAL_PRECISION) / getTotalVirtueStake();
  }

  /**
    @notice claimEthRewards is called to claim ETH rewards on behalf of a user.
    @param _user Address to claim rewards for
  */
  function claimEthRewards(address _user)
    public
    nonReentrant
  {
    uint currentRewards = getPendingETHGain(_user);
    if (currentRewards > 0) {
      claimedSnapshots[_user] = cumulativeETH;
      Address.sendValue(payable(_user), currentRewards);
    }
  }

  /**
    @notice claimExtraRewards is called to claim any rewards from linked extraRewards contracts
      on behalf of a user.
    @param _user Address to claim rewards for.
  */
  function claimExtraRewards(address _user) public nonReentrant {
    for (uint i = 0; i < extraRewards.length; i++) {
      IRewards(extraRewards[i]).claimRewards(_user);
    }
  }

  modifier onlyMintContract {
    require(msg.sender == mintContractAddress);
    _;
  }
}