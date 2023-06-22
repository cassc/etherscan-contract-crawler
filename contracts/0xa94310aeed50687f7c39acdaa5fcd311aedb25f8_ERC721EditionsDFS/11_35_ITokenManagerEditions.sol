// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./ITokenManager.sol";

/**
 * @title ITokenManager
 * @author [email protected]
 * @notice Enables interfacing with custom token managers for editions contracts
 */
interface ITokenManagerEditions is ITokenManager {
    /**
     * @notice The updated field in metadata updates
     */
    enum FieldUpdated {
        name,
        description,
        imageUrl,
        animationUrl,
        externalUrl,
        attributes,
        other
    }

    /**
     * @notice Returns whether metadata updater is allowed to update
     * @param editionsAddress Address of editions contract
     * @param sender Updater
     * @param editionId Token/edition who's uri is being updated
     *           If id is 0, implementation should decide behaviour for base uri update
     * @param newData Token's new uri if called by general contract, and any metadata field if called by editions
     * @param fieldUpdated Which metadata field was updated
     * @return If invocation can update metadata
     */
    function canUpdateEditionsMetadata(
        address editionsAddress,
        address sender,
        uint256 editionId,
        bytes calldata newData,
        FieldUpdated fieldUpdated
    ) external returns (bool);
}