// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IDeck {
    struct Cohort {
        uint256[] ids;
        bytes32 randomHash;
    }

    event CohortNumberIncremented(uint256 indexed cohortNumber);
    event CohortRandomHashSet(uint256 indexed cohortNumber, bytes32 indexed randomHash);

    /**
     * @return bool If the mint is open or not
     **/
    function canMint() external view returns (bool);

    /**
     * @return uint256 The price of each NFT
     **/
    function mintFee() external view returns (uint256);

    /**
     * @return uint16 The current cohort
     **/
    function currentCohort() external view returns (uint16);

    /**
     * @param newBaseURI a cohort-shared base URI
     **/
    function setBaseURI(string memory newBaseURI, uint256 cohortId_) external;

    /// @dev this will increment the cohort so all new minters go into the next cohort.
    function incrementCohort() external;

    /**
     * @param cohortNumber the ID of a previous cohort. Can only be set once, and cannot be set on the active cohort.
     * @param randomHash A bytes32 hash that should be psuedo random, or at least difficult to manipulate to affect the outcome of the NFT randomization
     **/
    function setCohortRandomValue(uint16 cohortNumber, bytes32 randomHash) external;

    /**
     * @dev The ID length for a cohort number
     **/
    function cohortLength(uint16 cohortNumber) external view returns (uint256);

    /**
     * @return uint256 The max supply
     **/
    function maxCount() external view returns (uint256);

    /**
     * @return uint256 The max per wallet
     **/
    function maxCountPerWallet() external view returns (uint256);

    /**
     * @param cohortNum - Cohort number
     * @param index - The index of the ID in a cohort
     * @return uint
     **/
    function cohortId(uint16 cohortNum, uint256 index) external view returns (uint256);

    /**
     * @param count How many decks would you like?
     * @return bool - If the mint was successful
     **/
    function mintDeck(uint256 count) external payable returns (bool);

    /**
     * @param tokenId the NFT ID
     * @return bytes32 - the DNA of the deck
     **/
    function genesisSeed(uint256 tokenId) external view returns (bytes32);
}