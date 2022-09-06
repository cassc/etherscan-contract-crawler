// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

/*
 * @title The Parallel Identity Token (PID) interface
 * @author Parallel Markets Engineering Team
 * @dev See https://developer.parallelmarkets.com/docs/token for detailed documentation
 */
interface IParallelID is IERC721Upgradeable, IERC721MetadataUpgradeable, IERC721EnumerableUpgradeable {
    /*
     * @notice This event is emitted when a trait is added to a token for the first time.
     */
    event TraitAdded(uint256 indexed tokenId, string trait);

    /*
     * @notice This event is emitted when a trait is removed from a token.
     */
    event TraitRemoved(uint256 indexed tokenId, string trait);

    /*
     * @notice Emitted when there's a sanctions match in a monitored country
     * @param tokenId Numeric token id
     * @param countryId An ISO 3166 country code or UN M49 code for Interpol/Europol
     */
    event SanctionsMatch(uint256 indexed tokenId, uint256 countryId);

    function recipientMint(
        string memory tokenDataURI,
        string[] memory _traits,
        uint16 _subjectType,
        uint256 expiresAt,
        bytes calldata signature
    ) external payable returns (uint256);

    /*
     * @notice Determine whether or not a given token is still actively monitored for potential sanctions matches.
     */
    function isSanctionsMonitored(uint256 tokenId) external view returns (bool);

    /*
     * @notice Determine if the token holder is monitored for sanctions and doesn't have
     *     any sanctions matches.
     * @return true if the token holder is actively monitored and is not sanctioned
     */
    function isSanctionsSafe(uint256 tokenId) external view returns (bool);

    /*
     * @notice Determine if the token holder is monitored for sanctions and doesn't have
     *     any sanctions matches in the given country / region.
     * @param countryId An ISO 3166 country code or UN M49 code for Interpol/Europol
     * @return true if the token holder is actively monitored and is not sanctioned in the
     *     given country / region.
     */
    function isSanctionsSafeIn(uint256 tokenId, uint256 countryId) external view returns (bool);

    /*
     * @notice Get the entity type for the token holder
     * @return A constant representing the entity type (see SUBJECT_INDIVIDUAL / SUBJECT_BUSINESS)
     */
    function subjectType(uint256 tokenId) external view returns (uint16);

    /*
     * @return The approximate timestamp when the token was minted.
     */
    function mintedAt(uint256 tokenId) external view returns (uint256);

    /*
     * @notice Determine if a token contains a given trait
     * @param tokenId The token to consider
     * @param trait The string trait to look up in the token
     * @return true if the trait is present, false otherwise
     */
    function hasTrait(uint256 tokenId, string memory trait) external view returns (bool);

    /*
     * @notice Get a list of all traits set on the given token
     * @dev This may be very expensive, especially if the total number of available traits is large
     * @return An array of string traits
     */
    function traits(uint256 tokenId) external view returns (string[] memory);

    /*
     * Destroy a token and remove it from a wallet.
     */
    function burn(uint256 tokenId) external;
}