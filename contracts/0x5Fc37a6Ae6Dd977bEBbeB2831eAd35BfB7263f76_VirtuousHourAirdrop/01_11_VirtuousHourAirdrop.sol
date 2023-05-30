// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./VirtueToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
  @notice VirtuousHourAirdrop is an airdrop contract which allows authenticated users to claim a
    portion of the contract's VIRTUE based on how many Idol NFTs they minted within the eligible
    window.
*/
contract VirtuousHourAirdrop is Ownable {
  // virtueToken contains a reference to the ERC20 contract for the VIRTUE token.
  VirtueToken virtueToken;

  // merkleRoot is the value of the root of the Merkle Tree used for authenticating airdrop claims.
  bytes32 public merkleRoot;

  // totalVirtueReward stores the total amount of VIRTUE that is to be split between recipients.
  uint public totalVirtueReward;

  // totalShares holds the number of NFTs that were minted during the eligible window and dictates
  // how many ways totalVirtueReward will be divided.
  uint public totalShares;

  // rewardsStartTime specifies the timestamp when depositReward was called.
  uint public rewardsStartTime;

  // rewardsDuration specifies the amount of time that the VIRTUE rewards will be distributed
  // over.
  uint public rewardsDuration;

  // rewardDeposited is a one-time flag that is set to true once the VIRTUE reward has been
  // deposited into the contract and is ready to be claimed.
  bool public rewardDeposited = false;

  // alreadyClaimed stores the amount of rewards that each address has claimed.
  mapping(address => uint) public alreadyClaimed;

  event AirdropRewardDeposited(
    uint _virtueAmount,
    address _caller
  );

  constructor(
    bytes32 _merkleRoot,
    address _virtueTokenAddress,
    uint _totalShares
  ) {
    merkleRoot = _merkleRoot;
    virtueToken = VirtueToken(_virtueTokenAddress);
    totalShares = _totalShares;
  }

  /**
    @notice depositReward is a one-time function which deposits a set amount of VIRTUE token that
      can be claimed by airdrop recipients. The rewards are distributed over the duration of
      _rewardsDuration. The function requires the owner to first approve the VirtuousHourAirdrop
      contract to transfer the amount of VIRTUE token on its behalf.

      THIS FUNCTION CANNOT BE CALLED MORE THAN ONCE.
    @param _virtueAmount The amount of VIRTUE reward to distribute.
    @param _rewardsDuration The amount of time that the VIRTUE reward will distribute over.
  */
  function depositReward(uint _virtueAmount, uint _rewardsDuration) external onlyOwner {
    require(!rewardDeposited, "Reward has already been deposited");
    rewardDeposited = true;
    totalVirtueReward = _virtueAmount;
    rewardsStartTime = block.timestamp;
    rewardsDuration = _rewardsDuration;
    require(virtueToken.transferFrom(msg.sender, address(this), _virtueAmount));
    emit AirdropRewardDeposited(_virtueAmount, msg.sender);
  }

  /**
    @notice rewardPerShare returns the amount of VIRTUE rewards that have been distributed per
      share at the current point in time.
  */
  function rewardPerShare() public view returns (uint256) {
    return (lastTimeRewardApplicable() - rewardsStartTime) * totalVirtueReward / rewardsDuration / totalShares;
  }

  /**
    @notice lastTimeRewardApplicable returns the most recent timestamp where the rewards period was
      still active (which is the current timestamp if the rewards period is currently active).
  */
  function lastTimeRewardApplicable() public view returns (uint256) {
    return block.timestamp < rewardsStartTime + rewardsDuration ? block.timestamp : rewardsStartTime + rewardsDuration;
  }

  /**
    @notice claimableReward returns the amount that an address is eligible to claim, given a certain
      number of shares.
    @param _claimee The address to claim rewards for.
    @param _numShares The number of shares of rewards to claim.
  */
  function claimableReward(address _claimee, uint _numShares) public view returns(uint256) {
    return _numShares * rewardPerShare() - alreadyClaimed[_claimee];
  }

  /**
    @notice claimRewards will claim the VIRTUE rewards that an address is eligible to claim from the
      airdrop contract, based on how many NFTs they minted during the eligible window. The function
      must be called with the EXACT number of shares that the address is eligible to claim, i.e.
      if someone purchased 5 eligible NFTs and they try to claim with _numShares = 1, the
      transaction will be reverted -- they must claim exactly 5 shares.
    @param _to The address to claim rewards for.
    @param _numShares The number of shares (i.e. eligible NFTs purchased) of VIRTUE rewards to
      claim.
    @param _merkleProof The merkle proof used to authenticate the transaction against the Merkle
      root.
  */
  function claimRewards(address _to, uint _numShares, bytes32[] calldata _merkleProof) external {
    require(rewardDeposited, "Reward has not yet been deposited into contract");

    // Verify against the Merkle tree that the transaction is authenticated for the user.
    bytes32 leaf = keccak256(abi.encodePacked(_to, _numShares));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Failed to authenticate with merkle tree");

    uint rewardAmount = claimableReward(_to, _numShares);
    require(rewardAmount > 0, "No rewards available to claim");

    alreadyClaimed[_to] = alreadyClaimed[_to] + rewardAmount;
    require(virtueToken.transfer(_to, rewardAmount));
  }
}