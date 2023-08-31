// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "./IVerifiedSBT.sol";

/**
 * @title IQueryVerifier
 * @notice The QueryVerifier contract is used to verify the ZK proof followed by the issuance of an SBT token to the user.
 * This contract is inherited from iden3's ZKPVerifier contract, so it is fully compatible with PolygonID wallet
 */
interface IQueryVerifier {
    /**
     * @notice Structure that contains information about the verification of a specific user
     * @param senderAddr the address to which the SBT was minted
     * @param mintedTokenId the ID of the token that was minted
     */
    struct VerificationInfo {
        address senderAddr;
        uint256 mintedTokenId;
    }

    /**
     * @notice Event is emitted when a user has successfully validated using ZK proofs
     * @param userId the user ID in the iden3 system
     * @param userAddr the address to which the SBT token was minted
     * @param tokenId the ID of the token that was minted
     */
    event Verified(uint256 indexed userId, address indexed userAddr, uint256 tokenId);

    /**
     * @notice Function for updating the SBT contract address
     * @dev Only contract OWNER can call this contract
     * @param sbtContract_ the new SBT contract address
     */
    function setSBTContract(address sbtContract_) external;

    /**
     * @notice Function that returns the address of the SBT contract
     * @return The SBT contract address
     */
    function sbtContract() external view returns (IVerifiedSBT);

    /**
     * @notice Function that returns the user ID by specific address
     * @param userAddr_ the address for which the information is to be obtained
     * @return The user ID
     */
    function addressToUserId(address userAddr_) external view returns (uint256);

    /**
     * @notice Function that returns verification information for a specific user
     * @param userId_ the Id of the user for whom you want to get information
     * @return The VerificationInfo structure
     */
    function getVerificationInfo(uint256 userId_) external view returns (VerificationInfo memory);

    /**
     * @notice Function that checks whether the user is verified or not
     * @param userId_ the ID of the user to be checked
     * @return true if the user is already verified, otherwise false
     */
    function isUserVerified(uint256 userId_) external view returns (bool);
}