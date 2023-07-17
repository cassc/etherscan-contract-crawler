// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./staking/mixins/BalanceTrackingMixin.sol";
import "./staking/mixins/RewardTrackingMixin.sol";
import "./staking/mixins/RestrictedPairsMixin.sol";
import "./staking/ERC1155Staker.sol";

/**
 * @dev Staking contract for ERC1155 tokens which tracks rewards in ether.  All ether sent to this contract will be distributed
 * evenly across all stakers.
 * This contract only accepts whitelisted pairs of tokens to be staked.
 */
contract EulerBeatsPairStaking is
    ERC1155Staker,
    BalanceTrackingMixin,
    RewardTrackingMixin,
    RestrictedPairsMixin,
    ReentrancyGuard,
    Ownable
{
    bool public emergency;
    uint256 public maxPairs;

    event RewardAdded(uint256 amount);
    event RewardClaimed(address indexed account, uint256 amount);

    // on stake/unstake
    event PairStaked(uint256 indexed pairId, address indexed account, uint256 amount);
    event PairUnstaked(uint256 indexed pairId, address indexed account, uint256 amount);

    event EmergencyUnstake(uint256 pairId, address indexed account, uint256 amount);

    /**
     * @dev The token contracts to allow the pairs from.  These address can only be set in the constructor, so make
     * sure you have it right!
     */
    constructor(address tokenAddressA, address tokenAddressB) RestrictedPairsMixin(tokenAddressA, tokenAddressB) {}

    /**
     * @dev Claim the reward for the caller.
     */
    function claimReward() external nonReentrant {
        claimRewardInternal();
    }

    /**
     * @dev Stake amount of tokens for the given pair.  Prior to staking, this will send and pending reward to the caller.
     */
    function stake(uint256 pairId, uint256 amount) external onlyEnabledPair(pairId) nonReentrant {
        require(totalShares + amount <= maxPairs, "Max Pairs Exceeded");
        require(!emergency, "Not allowed");

        // claim any pending reward
        claimRewardInternal();

        // transfer tokens from account to staking contract
        depositPair(pairId, amount);

        // update reward balance
        _addShares(msg.sender, amount);
    }

    /**
     * @dev Unstake one or more tokens.  Prior to unstaking, this will send all pending rewards to the caller.
     */
    function unstake(uint256 pairId, uint256 amount) external nonReentrant {
        // claim any pending reward
        claimRewardInternal();

        // transfer tokens from staking contract to account
        withdrawPair(pairId, amount);

        // update reward balance
        _removeShares(msg.sender, amount);
    }

    /**
     * @dev Unstake the given pair and forfeit any current pending reward.  This is only for emergency use
     * and will mess up this account's ability to unstake any other pairs.
     * If used, the caller should unstake ALL pairs (each pair id one-by-one) using this function.
     */
    function emergencyUnstake(uint256 pairId, uint256 amount) external nonReentrant {
        require(emergency, "Not allowed");
        require(amount > 0, "Invalid amount");

        // reset this account back to 0 rewards
        _resetRewardAccount(msg.sender);

        // trasfers the tokens back to the account
        withdrawPair(pairId, amount);

        emit EmergencyUnstake(pairId, msg.sender, amount);
    }

    /**
     * @dev Add rewards that are immediately split up between stakers
     */
    function addReward() external payable {
        require(msg.value > 0, "No ETH sent");
        require(totalShares > 0, "No stakers");
        _addReward(msg.value);
        emit RewardAdded(msg.value);
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    ///////////////
    // Hooks     //
    ///////////////

    function _beforeDeposit(
        address account,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal virtual override {
        // update deposit balance for the given account
        _depositIntoAccount(account, contractAddress, tokenId, amount);
    }

    function _beforeWithdraw(
        address account,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal virtual override {
        // update deposit balance for the given account.  this will revert if someone
        // is trying to withdraw more than they have deposited.
        _withdrawFromAccount(account, contractAddress, tokenId, amount);
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    ///////////////
    // Getters   //
    ///////////////

    /**
     * @dev Return the current number of staked pairs.
     */
    function numStakedPairs() external view returns (uint256) {
        return totalShares;
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    ///////////////
    // Internal  //
    ///////////////

    /**
     * @dev Send any pending reward to msg.sender and update their debt so they
     * no longer have any pending reward.
     */
    function claimRewardInternal() internal {
        uint256 currentReward = accountPendingReward(msg.sender);
        if (currentReward > 0) {
            _updateRewardDebtToCurrent(msg.sender);

            uint256 amount;
            if (currentReward > address(this).balance) {
                // rounding errors
                amount = address(this).balance;
            } else {
                amount = currentReward;
            }
            Address.sendValue(payable(msg.sender), amount);
            emit RewardClaimed(msg.sender, amount);
        }
    }

    function depositPair(uint256 pairId, uint256 amount) internal {
        PairInfo memory pair = pairs[pairId];
        _depositSingle(tokenA, pair.tokenIdA, amount);
        _depositSingle(tokenB, pair.tokenIdB, amount);
        emit PairStaked(pairId, msg.sender, amount);
    }

    function withdrawPair(uint256 pairId, uint256 amount) internal {
        PairInfo memory pair = pairs[pairId];
        _withdrawSingle(tokenA, pair.tokenIdA, amount);
        _withdrawSingle(tokenB, pair.tokenIdB, amount);
        emit PairUnstaked(pairId, msg.sender, amount);
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    ///////////////
    // Admin     //
    ///////////////

    /**
     * @dev Add new pairs that can be staked.  Pairs can never be removed after this call, only disabled.
     */
    function addPairs(
        uint256[] memory tokenIdA,
        uint256[] memory tokenIdB,
        bool[] memory enabled
    ) external onlyOwner {
        _addPairs(tokenIdA, tokenIdB, enabled);
    }

    /**
     * @dev Toggle the ability to stake in the given pairIds.  Stakers can always withdraw, regardless of
     * this flag.
     */
    function enablePairs(uint256[] memory pairIds, bool[] memory enabled) external onlyOwner {
        _enablePairs(pairIds, enabled);
    }

    /**
     * @dev Set the maximum number of pairs that can be staked at any point in time.
     */
    function setMaxPairs(uint256 amount) external onlyOwner {
        maxPairs = amount;
    }

    /**

     * @dev Withdraw any unclaimed eth in the contract.  Can only be called if there are no stakers.
     */
    function withdrawUnclaimed() external onlyOwner {
        require(totalShares == 0, "Stakers");
        // send any unclaimed eth to the owner
        if (address(this).balance > 0) {
            Address.sendValue(payable(msg.sender), address(this).balance);
        }
    }

    /**
     * @dev Set the emergency flag
     */
    function setEmergency(bool value) external onlyOwner {
        emergency = value;
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
}