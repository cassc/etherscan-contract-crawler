// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "./interfaces/IDownline.sol";

/**
 * @title Furio Referrals
 * @author Steve Harmeyer
 * @notice This contract keeps track of referrals and referral rewards.
 */

/// @custom:security-contact [email protected]
contract Referrals is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
        maxDepth = 15;
    }

    /**
     * Addresses.
     */
    address devWalletAddress;
    address downlineNftAddress;
    address vaultAddress;

    /**
     * Referrals.
     */
    uint256 public maxDepth;
    mapping(address => address) public referrer;
    mapping(address => uint256) public referralCount;
    mapping(address => address[]) public referrals;
    mapping(address => address) public lastRewarded;
    mapping(address => address) public lastRewardedBy;
    mapping(address => uint256) public rewardCount;

    /**
     * Update addresses.
     */
    function updateAddresses() public
    {
        if(devWalletAddress == address(0)) devWalletAddress = addressBook.get("safe");
        if(downlineNftAddress == address(0)) downlineNftAddress = addressBook.get("downline");
        if(vaultAddress == address(0)) vaultAddress = addressBook.get("vault");
    }

    /**
     * Add participant.
     * @param participant_ Participant address.
     * @param referrer_ Referrer address.
     */
    function addParticipant(address participant_, address referrer_) external onlyVault
    {
        _addParticipant(participant_, referrer_);
    }

    /**
     * Internal add participant.
     * @param participant_ Participant address.
     * @param referrer_ Referrer address.
     */
    function _addParticipant(address participant_, address referrer_) internal
    {
        require(devWalletAddress != address(0), "Dev wallet not yet set");
        require(participant_ != address(0), "Participant address is 0");
        require(referrer_ != address(0), "Referrer address is 0");
        require(participant_ != referrer_, "Participant cannot be referrer");
        referrer[participant_] = referrer_;
        referralCount[referrer_] ++;
        referrals[referrer_].push(participant_);
        lastRewarded[participant_] = participant_;
    }

    /**
     * Get next reward address.
     * @param participant_ Participant address.
     * @return address Next reward address.
     */
    function getNextRewardAddress(address participant_) external returns (address)
    {
        return _getNextRewardAddress(participant_, 1);
    }

    /**
     * Reward upline.
     * @param participant_ Participant address.
     * @return address Reward address.
     */
    function rewardUpline(address participant_) external onlyVault returns (address)
    {
        address _next_ = _getNextRewardAddress(participant_, 1);
        lastRewarded[participant_] = _next_;
        lastRewardedBy[_next_] = participant_;
        rewardCount[_next_] ++;
        return _next_;
    }

    /**
     * Internal get next reward address.
     * @param participant_ Participant address.
     * @param depth_ Referral depth.
     * @return address Next reward address.
     */
    function _getNextRewardAddress(address participant_, uint256 depth_) internal returns (address)
    {
        if(depth_ > maxDepth) return devWalletAddress;
        address _lastRewarded_ = lastRewarded[participant_];
        if(_lastRewarded_ == address(0) || _lastRewarded_ == devWalletAddress) _lastRewarded_ = participant_;
        address _next_ = referrer[_lastRewarded_];
        if(_next_ == address(0)) return devWalletAddress;
        IDownline _downline_ = IDownline(downlineNftAddress);
        if(_downline_.balanceOf(_next_) < depth_) return _getNextRewardAddress(_next_, depth_ + 1);
        return _next_;
    }

    /**
     * Update referrer.
     * @param referrer_ New referrer address.
     */
    function updateReferrer(address referrer_) external
    {
        require(referrer[msg.sender] == address(0), "You already have a referrer");
        _addParticipant(msg.sender, referrer_);
    }

    /**
     * Only vault.
     */
    modifier onlyVault
    {
        require(msg.sender == vaultAddress, "Only the vault can call this function");
        _;
    }
}