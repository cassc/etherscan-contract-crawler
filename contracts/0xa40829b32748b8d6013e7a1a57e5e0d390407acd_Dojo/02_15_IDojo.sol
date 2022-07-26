// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/**
 * Dojo Interface
 */
interface IDojo is IERC721, IERC721Metadata, IERC721Receiver {

    event CollectedXP(
        address indexed sender,
        uint256[] dojoIds,
        uint32[] amounts
    );

    struct Bandana {
        string name;
        uint208 xpThreshold;
    }

    struct StakedOwner {
        address ownerAddress;
        uint48 entryTime;
    }

    struct XP {
        uint208 value;
        uint48 lastUpdateTime;
    }

    /**
     * @dev Get a chimp's finalized XP
     */
    function chimpXP(uint256 tokenId, bool isGenesisChimp) external view returns(uint208);

    /**
     * @dev Get a chimp's finalized bandana
     */
    function chimpBandana(uint256 tokenId, bool isGenesisChimp) external view returns(string memory);

    /**
     * @dev Get the list of available bandanas
     */
    function bandanas() external view returns(Bandana[] memory);

    /**
     * @dev Set the server oracle signing address
     *
     * Requirements:
     * 
     * - The caller must be an admin
     */
    function setSigningAddress(address signingAddress) external;

    /**
     * @dev Set the base URI for token metadata
     *
     * Requirements:
     * 
     * - The caller must be an admin
     */
    function setTokenURI(string calldata uri) external;

    /**
     * @dev Set the XP thresholds and bandana levels 
     *
     * Requirements:
     * 
     * - The caller must be an admin
     */
    function setBandanas(uint32[] calldata xpThresholds, string[] calldata bandanaNames) external;

    /**
     * @dev Set the maxmimum daily XP a chimp can earn.
     *
     * Requirements:
     * 
     * - The caller must be an admin
     */
    function setMaxDailyXP(uint32 xp) external;

    /**
     * @dev Open the Dojo.
     *
     * Requirements:
     * 
     * - The caller must be an admin
     */
    function openDojo() external;

    /**
     * @dev Collect accumulated XP.
     */
    function collectXP(
        uint256[] calldata dojoIds,
        uint32[] calldata amounts,
        bytes32 message,
        bytes calldata signature,
        bytes32 nonce
    ) external;

    /**
     * @dev Enter the Dojo. Used for sending many chimps to the Dojo in one transaction.
     * 
     * Requirements:
     * 
     * - This contract must be an approved operator for each token
     */
    function enterDojo(
        uint256[] calldata tokenIds,
        address[] calldata tokenAddresses
    ) external;

    /**
     * @dev Leave the Dojo. Returns original chimps to caller and reclaims staked chimps
     * from caller to this contract.
     * 
     * Requirements:
     * 
     * - The caller must own the staked chimps with the provided `dojoIds`
     */
    function exitDojo(
        uint256[] calldata dojoIds,
        uint32[] calldata xpList,
        bytes32 message,
        bytes calldata signature,
        bytes32 nonce
    ) external;

    /**
     * @dev Return a lost chimp to address (if the chimp is sent to this contract with 
     * transferFrom)
     * 
     * Requirements:
     * 
     * - The caller must be an admin
     */
    function returnLostChimp(address to, bool isGenesisChimp, uint256 tokenId) external;

    /**
     * @dev Check if nonce has been used
     */
    function nonceUsed(bytes32 nonce) external view returns(bool);
}