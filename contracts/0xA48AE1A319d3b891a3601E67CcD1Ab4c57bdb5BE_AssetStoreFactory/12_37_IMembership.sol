//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../structs/MembershipPlansStruct.sol";
import "../structs/MembershipStruct.sol";

/**
 * @title Interface for IMembership
 * @dev to interact with Membership
 */
interface IMembership {
    /**
     * @dev Function to check of membership is active for the user
     * @param _uid string identifier of user across dApp
     * @return bool boolean representing if the membership has expired
     *
     */
    function checkIfMembershipActive(string memory _uid)
        external
        view
        returns (bool);

    /**
     * @dev renewmembership Function to renew membership of the user
     * @param _uid string identifier of the user renewing membership
     *
     *
     */
    function renewMembership(string memory _uid) external payable;

    /**
     * @dev renewmembershipNFT - Function to renew membership for users that have NFTs
     * @param _contractAddress address of nft to approve renewing
     * @param _NFTType string type of NFT i.e. ERC20 | ERC1155 | ERC721
     * @param tokenId uint256 tokenId being protected
     * @param _uid string identifier of the user renewing membership
     *
     */
    function renewMembershipNFT(
        address _contractAddress,
        string memory _NFTType,
        uint256 tokenId,
        string memory _uid
    ) external payable;

    /**
     * @dev Function to top up updates
     * @param _uid string identifier of the user across the dApp
     *
     */
    function topUpUpdates(string memory _uid) external payable;

    /**
     * @notice changeMembershipPlan
     * Ability to change membership plan for a member given a membership ID and member UID.
     * It is a payable function given the membership cost for the membership plan.
     *
     * @param membershipId uint256 id of membership plan changing to
     * @param _uid string identifier of the user
     */
    function changeMembershipPlan(uint256 membershipId, string memory _uid)
        external
        payable;

    /**
     * @notice changeMembershipPlanNFT - Function to change membership plan to an NFT based plan
     * @param membershipId uint256 id of the membershipPlan changing to
     * @param _contractAddress address of the NFT granting the membership
     * @param _NFTType string type of NFT i.e. ERC721 | ERC1155
     * @param tokenId uint256 tokenId of the nft to verify ownership
     * @param _uid string identifier of the user across the dApp
     *
     */
    function changeMembershipPlanNFT(
        uint256 membershipId,
        address _contractAddress,
        string memory _NFTType,
        uint256 tokenId,
        string memory _uid
    ) external payable;

    /**
     * @notice redeemUpdate
     * @param _uid string identifier of the user across the dApp
     *
     * Function to claim that a membership has been updated
     */
    function redeemUpdate(string memory _uid) external;

    /**
     * @notice Function to return membership information of the user
     * @param _uid string identifier of user across dApp
     * @return MembershipStruct containing information of the specific user's membership
     *
     */
    function getMembership(string memory _uid)
        external
        view
        returns (MembershipStruct memory);
}