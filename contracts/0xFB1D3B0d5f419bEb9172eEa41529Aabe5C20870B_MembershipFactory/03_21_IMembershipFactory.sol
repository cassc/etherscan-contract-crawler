//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../structs/MembershipPlansStruct.sol";

/**
 * @title Interface for IMembershipFactory to interact with Membership Factory
 *
 */
interface IMembershipFactory {
    /**
     * @dev Function to createMembership by deploying membership contract for a specific member
     * @param uid string identifier of a user across the dApp
     * @param _membershipId uint256 id of the chosen membership plan
     * @param _walletAddress address of the user creating the membership
     *
     */
    function createMembership(
        string calldata uid,
        uint256 _membershipId,
        address _walletAddress
    ) external payable;

    /**
     * @dev Function to create Membership for a member with supporting NFTs
     * @param uid string identifier of the user across the dApp
     * @param _contractAddress address of the NFT granting membership
     * @param _NFTType string type of NFT for granting membership i.e. ERC721 | ERC1155
     * @param tokenId uint256 tokenId of the owned nft to verify ownership
     * @param _walletAddress address of the user creating a membership with their nft
     *
     */
    function createMembershipSupportingNFT(
        string calldata uid,
        address _contractAddress,
        string memory _NFTType,
        uint256 tokenId,
        address _walletAddress
    ) external payable;

    /**
     * @dev function to get all membership plans
     * @return membershipPlan[] a list of all membershipPlans on the contract
     *
     */
    function getAllMembershipPlans()
        external
        view
        returns (membershipPlan[] memory);

    /**
     * @dev function to getCostOfMembershipPlan
     * @param _membershipId uint256 id of specific plan to retrieve
     * @return membershipPlan struct
     *
     */
    function getMembershipPlan(uint256 _membershipId)
        external
        view
        returns (membershipPlan memory);

    /**
     * @dev Function to get updates per year cost
     * @return uint256 cost of updating membership in wei
     *
     */
    function getUpdatesPerYearCost() external view returns (uint256);

    /**
     * @dev Function to set new membership plan for user
     * @param _uid string identifing the user across the dApp
     * @param _membershipId uint256 id of the membership for the user
     *
     */
    function setUserForMembershipPlan(string memory _uid, uint256 _membershipId)
        external;

    /**
     * @dev Function to transfer eth to specific pool
     *
     */
    function transferToPool() external payable;

    /**
     * @dev Function to return users membership contract address
     * @param _uid string identifier of a user across the dApp
     * @return address of the membership contract if exists for the _uid
     *
     */
    function getUserMembershipAddress(string memory _uid)
        external
        view
        returns (address);
}