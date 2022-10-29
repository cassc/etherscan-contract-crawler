//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Membership Structure stores membership data of a member
 * @param user address of the user who has a membership
 * @param membershipStarted uint256 timestamp of when the membership began
 * @param membershipEnded uint256 timestamp of when membership expires
 * @param payedAmount uint256 amount in wei paid for the membership
 * @param active bool status of the user's membership
 * @param membershipId uint256 id of the membershipPlan this was created for
 * @param updatesPerYear uint256 how many updates per year left for the user
 * @param nftCollection address of the nft collection granting a membership or address(0)
 * @param uid string of the identifier of the user across the dApp
 * 
 */
struct MembershipStruct {
    address user;
    uint256 membershipStarted;
    uint256 membershipEnded;
    uint256 payedAmount;
    bool active;
    uint256 membershipId;
    uint256 updatesPerYear;
    address nftCollection;
    string uid;
}