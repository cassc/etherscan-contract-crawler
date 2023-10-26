//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../libraries/DataTypes.sol";

struct FeeDistribution {
    uint256 protocol;
    uint256 referrer;
    uint256 trader;
    address referrerAddress;
}

interface IReferralManagerEvents {

    event RewardsAndRebatesSet(uint256 referrerReward, uint256 traderRebate);
    event ReferralCodeRegistered(address indexed referrer, bytes32 referralCode);
    event TraderReferred(address indexed trader, address indexed referrer, bytes32 indexed referralCode);

}

interface IReferralManager is IReferralManagerEvents {

    error ReferralCodeInvalid(bytes32 code); // 0x66f70111
    error ReferralCodeAlreadySet(bytes32 code); // 0xb7f957d0
    error ReferralCodeUnavailable(bytes32 code); // 0x244fbb46
    error ReferralCodeNotRegistered(bytes32 code); // 0x7b85b5e5
    error CannotSelfRefer(); // 0xd1affa92
    error RewardsConfigCannotExceedMax(); // 0xd483d656

    // @notice Sets the rewards and rebates for referrals
    // @param referrerReward The percentage of fees to reward the referrer
    // @param traderRebate The percentage of fees to rebate the trader
    // @dev The sum of referrerReward and traderRebate cannot exceed 100%
    // @dev The precision of the rewards and rebates is 1e4 == 100%
    function setRewardsAndRebates(uint256 referrerReward, uint256 traderRebate) external;

    // @notice Checks if a referral code is available
    // @param code The referral code to check
    function isCodeAvailable(bytes32 code) external view returns (bool);

    // @notice Registers a referral code for the caller
    // @param code The referral code to register
    function registerReferralCode(bytes32 code) external;

    // @notice Sets the referrer for the caller
    // @param code The referral code to use
    function setTraderReferralByCode(bytes32 code) external;

    // @notice Sets the referrer for a given address
    // @param code The referral code to use
    // @param trader The trader to set the referrer for
    function setTraderReferralByCodeForAddress(bytes32 code, address trader) external;

    // @notice Determines the distribution for a given amount to the protocol, referrer, and trader
    // @param trader The trader used to lookup the referrer
    // @param amount The amount to distribute
    function calculateRewardDistribution(address trader, uint256 amount) external view returns (FeeDistribution memory);

}