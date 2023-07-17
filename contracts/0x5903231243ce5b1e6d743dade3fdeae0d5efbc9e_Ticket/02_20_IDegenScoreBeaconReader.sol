// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../structs/Contract.sol";

interface IDegenScoreBeaconReader {
    /**
     * @dev returns the Beacon data for a account
     * @param account the address of the Beacon holder
     * @return beaconData the metadata of a Beacon holder
     */
    function beaconDataOf(address account) external view returns (BeaconData memory);

    /**
     * @dev returns the owner address of a beaconId
     * @param beaconId the Beacon ID
     * @return owner the address of the Beacon owner
     */
    function ownerOfBeacon(uint128 beaconId) external view returns (address owner);

    /**
     * @notice This is used to lookup a Trait of a account.
     * `maxAge` can be used to only return a Trait value if the Trait is not older than the specified age.
     * If no Trait is found or the Trait is older than `maxAge` it returns 0
     * @dev returns the value for a primary Trait of a account
     * @param account the address of the user
     * @param traitId the Trait ID of the primary Trait
     * @param maxAge the maximum age of a Trait in seconds
     */
    function getTrait(
        address account,
        uint256 traitId,
        uint64 maxAge
    ) external view returns (uint192);

    /**
     * @notice Lookup traits in batches
     */
    function getTraitBatch(
        address[] memory accounts,
        uint256[] memory traitIds,
        uint64[] memory maxAges
    ) external view returns (uint192[] memory);

    /**
     * @notice returns all traits of an account
     * @param account the address of the account to lookup
     * @return traitIds the primary Trait IDs of the account
     * @return traitValues the values for each Trait ID
     * @return updatedAt the timestamp of when the Beacon was updated
     */
    function getAllTraitsOf(address account)
        external
        view
        returns (
            uint256[] memory traitIds,
            uint192[] memory traitValues,
            uint64 updatedAt
        );

    /**
     * @dev returns the metadata URL for the `traitId`
     * @param traitId the ID of the primary Trait
     * @return url the URL of the Trait metadata
     */
    function getTraitURI(uint256 traitId) external view returns (string memory);

    /**
     * @dev returns the metadata URL of the Beacon. This is used to get secondary traits.
     * @param beaconId the ID of the Beacon
     * @return url the URL of the Beacon metadata
     */
    function getBeaconURI(uint128 beaconId) external view returns (string memory);
}