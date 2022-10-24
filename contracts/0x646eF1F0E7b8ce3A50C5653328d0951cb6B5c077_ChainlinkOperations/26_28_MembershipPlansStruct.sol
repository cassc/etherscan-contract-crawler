//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev membershipPlan struct
 * 
 * @param membershipDuration uint256 length of time membership is good for
 * @param costOfMembership uint256 cost in wei of gaining membership
 * @param updatesPerYear uint256 how many updates can the membership be updated in a year by user
 * @param nftCollection address pass as null address if it is not for creating specific
 * membership plan for a specific NFT Collection
 * @param membershipId uint256 id for the new membership to lookup by
 * @param active bool status if the membership can be used to create new contracts
 */
struct membershipPlan {
    uint256 membershipDuration;
    uint256 costOfMembership;
    uint256 updatesPerYear;
    address nftCollection;
    uint256 membershipId;
    bool active;
}