// SPDX-FileCopyrightText: © Courtyard Inc. (https://courtyard.io)
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


/**
 * The relevant interface of the Golden Egg Club NFT contract
 * Note: The deployed contract does not expose its token existence or supply accessors.
 */
interface IGoldenEggClub {
    function ownerOf(uint256 tokenId) external returns (address owner);
}


/**
 * The relevant interface of the Courtyard Registry contract
 */
interface ICourtyardRegistry {
    function generateProofOfIntegrity(string memory fingerprint, uint256 salt) external pure returns (bytes32);
    function getTokenId(bytes32 proofOfIntegrity) external view returns (uint256);
    function mintToken(address to, bytes32 proofOfIntegrity) external returns (uint256);
}


/**
 * @title Minter contract for the Golden Egg Club X Courtyard collaboration.
 * A few notes:
 *  - This contract handles the business logic behind the drop of a golden egg for the owners of the original Golden Egg Club NFT.
 *  - Each Golden Egg Club NFT owner can claim the corresponding golden egg that is secured by Courtyard.
 *  - A particular Golden Egg Club NFT can only be used once to claim the corresponding golden egg.
 *  - Before purchasing a Golden Egg Club NFT with the intent to claim the corresponding golden egg, please double check that
 * it has not been claimed yet. 
 */ 
contract GoldenEggClubXCourtyardDrop is Context, ReentrancyGuard, Ownable {

    using Strings for uint256;

    event GoldenEggClaimed(uint256 indexed goldenEggClubTokenId, address indexed claimer);

    IGoldenEggClub public immutable goldenEggClubContract;  // the Golden Egg Club NFT contract.
    ICourtyardRegistry public immutable courtyardRegistry;  // the address of the Courtyard registry that holds the golden egg.
    bool[222] _claimedGoldenEggs;                           // keeps track of the Golden Egg Club NFTs that were successfully claimed.
                                                            // indexes are shifted by 1, so that the Golden Egg Club NFTs with
                                                            // goldenEggClubTokenId {ii} is represented by _claimedGoldenEggs[ii-1]
    bool public isClaimingWindowOpen = false;               // flag used to control the claiming window.

    /* ================================================ CONSTRUCTOR ================================================ */

    /**
     * @dev Constructor.
     *  - Sets the Golden Egg Club NFT contract address. This cannot be changed.
     *  - Sets the Courtyard registry that holds the golden egg. This cannot be changed.
     */
    constructor(address goldenEggClubContractAddress, address courtyardRegistryAddress) {
        goldenEggClubContract = IGoldenEggClub(goldenEggClubContractAddress);
        courtyardRegistry = ICourtyardRegistry(courtyardRegistryAddress);
    }


    /* ========================================= CLAIMING WINDOW CONTROLS ========================================= */

    /**
     * @dev Check that the claiming window is open.
     */
    modifier onlyClaimingWindowOpen {
        require(isClaimingWindowOpen, "GoldenEggClubXCourtyardDrop: The claiming window is closed.");
        _ ;
    }

    /**
     * @dev Open the claiming window.
     */
    function openClaimingWindow() public onlyOwner {
        isClaimingWindowOpen = true;
    }    

    /**
     * @dev Close the claiming window.
     */
    function closeClaimingWindow() public onlyOwner {
        isClaimingWindowOpen = false;
    }


    /* ============================================= INTERNAL HELPERS ============================================= */

    /**
     * @dev helper function to convert a Golden Egg Club NFT's goldenEggClubTokenId to a padded string.
     * 
     *  - goldenEggClubTokenId 1 to 9 -> "001" to "009"
     *  - goldenEggClubTokenId 10 to 99 -> "010" to "099"
     *  - goldenEggClubTokenId 100 to 222 -> "100" to "222"
     * 
     * Optimization note: this function being private, it can only be called from within this smart contract,
     * and the calling function must have checked that the {goldenEggClubTokenId} is supported using the
     * {onlySupportedGoldenEggClubToken} modifier.
     */
    function _toPaddedString(uint256 goldenEggClubTokenId) private pure returns (string memory) {
        if (goldenEggClubTokenId < 10) {
            return string(abi.encodePacked("00", goldenEggClubTokenId.toString()));
        } else if (goldenEggClubTokenId < 100) {
            return string(abi.encodePacked("0", goldenEggClubTokenId.toString()));
        } else {
            return goldenEggClubTokenId.toString();
        }
    }

    /**
     * @dev construct the fingerprint for a particular golden egg, so that it can be used to 
     * generate the Proof of Integrity using the {courtyardRegistry}.
     * 
     * Optimization note: this function being private, it can only be called from within this smart contract,
     * and the calling function must have checked that the {goldenEggClubTokenId} is supported using the
     * {onlySupportedGoldenEggClubToken} modifier.
     */
    function _courtyardFingerprint(uint256 goldenEggClubTokenId) private pure returns (string memory) {
        string memory paddedTokenId = _toPaddedString(goldenEggClubTokenId);
        return string(abi.encodePacked("Golden Egg Club X Courtyard | 23K gold plated golden egg #", paddedTokenId, " | CYxGEC_GE_", paddedTokenId));    
    }

    /**
     * @dev get the Proof of Integrity of a golden egg that has been minted in the {courtyardRegistry}, given the 
     * token id of the corresponding original Golden Egg Club NFT.
     *
     * Optimization note: this function being private, it can only be called from within this smart contract,
     * and the calling function must have checked that the {goldenEggClubTokenId} is supported using the
     * {onlySupportedGoldenEggClubToken} modifier.
     */
    function _courtyardProofOfIntegrity(uint256 goldenEggClubTokenId) private view returns (bytes32) {
        return courtyardRegistry.generateProofOfIntegrity(_courtyardFingerprint(goldenEggClubTokenId), 0);
    }

    /**
     * @dev mark a particular {goldenEggClubTokenId} as claimed.
     */   
    function _markAsClaimed(uint256 goldenEggClubTokenId) private {
        _claimedGoldenEggs[goldenEggClubTokenId - 1] = true;
    }


    /* ============================================= EXTERNAL HELPERS ============================================= */

    /**
     * @dev modifier to ensure that a requested Golden Egg Club token id is supported, i.e. there is golden egg 
     * for it. This extra check will ensure that if the owner of the Golden Egg Club smart contract decides to mint new
     * tokens that were not accounted for in the scope of this project, the owners of those new tokens would not be able
     * to claim a non existent golden egg.
     * 
     * Note: The scope of this collaboration covers 222 Golden Egg Club NTFs with the token IDs ranging from 1 to 222.
     */
    modifier onlySupportedGoldenEggClubToken(uint256 goldenEggClubTokenId) {
        require(goldenEggClubTokenId > 0 && goldenEggClubTokenId <= 222, "GoldenEggClubXCourtyardDrop: Request for a non supported Golden Egg Club token.");
        _ ;
    }

    /**
     * @dev checks if a Golden Egg Club NFT is still available to claim.
     * @return true if the Golden Egg Club NFT can still be used to claim the corresponding golden egg, and
     * false if it has already been used.
     */
    function isClaimed(uint256 goldenEggClubTokenId) public view onlySupportedGoldenEggClubToken(goldenEggClubTokenId) returns (bool) {
        return _claimedGoldenEggs[goldenEggClubTokenId - 1];
    }

    /**
     * @dev construct the fingerprint for a particular golden egg, so that it can be used to 
     * generate the Proof of Integrity using the {courtyardRegistry}.
     * This also serves as a helper for external applications to deterministically create the
     * fingerprint of the golden eggs.
     * 
     * Requirement: the {goldenEggClubTokenId} must be supported.
     */
    function getCourtyardFingerprint(uint256 goldenEggClubTokenId) public pure onlySupportedGoldenEggClubToken(goldenEggClubTokenId) returns (string memory) {
        return _courtyardFingerprint(goldenEggClubTokenId);
    }

    /**
     * @dev get the token id of a golden egg that has been minted in the {courtyardRegistry}, given the 
     * token id of the corresponding original Golden Egg Club NFT.
     * This also serves as a helper for external applications to expose that token id. 
     * 
     * Requirement: the {goldenEggClubTokenId} must be supported.
     */
    function getCourtyardTokenId(uint256 goldenEggClubTokenId) public view onlySupportedGoldenEggClubToken(goldenEggClubTokenId) returns (uint256) {
        return courtyardRegistry.getTokenId(_courtyardProofOfIntegrity(goldenEggClubTokenId));
    }


    /* ================================================== MINTING ================================================== */

    /**
     * @dev Claim a golden egg.
     * 
     * Requirements:
     *  - the claiming window must be open.
     *  - the caller must own the Golden Egg Club NFT used to claim the corresponding golden egg.
     *  - the Golden Egg Club NFT used for the claim must not have been already used to claim the corresponding golden egg.
     */
    function claimGoldenEgg(uint256 goldenEggClubTokenId) external nonReentrant onlyClaimingWindowOpen onlySupportedGoldenEggClubToken(goldenEggClubTokenId) {
        address caller = _msgSender();
        require(goldenEggClubContract.ownerOf(goldenEggClubTokenId) == caller, "GoldenEggClubXCourtyardDrop: Caller does not own the Golden Egg Club NFT claimed.");
        require(!isClaimed(goldenEggClubTokenId), "GoldenEggClubXCourtyardDrop: Golden Egg Club token already claimed.");
        courtyardRegistry.mintToken(caller, _courtyardProofOfIntegrity(goldenEggClubTokenId));
        _markAsClaimed(goldenEggClubTokenId);
        emit GoldenEggClaimed(goldenEggClubTokenId, caller);
    }

}