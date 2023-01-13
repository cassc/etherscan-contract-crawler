// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @title ITokenManager
 * @author [email protected]
 * @notice Enables interfacing with custom token managers
 */
interface ITokenManager {
    /**
     * @notice Returns whether metadata updater is allowed to update
     * @param sender Updater
     * @param id Token/edition who's uri is being updated
     *           If id is 0, implementation should decide behaviour for base uri update
     * @param newData Token's new uri if called by general contract, and any metadata field if called by editions
     * @return If invocation can update metadata
     */
    function canUpdateMetadata(
        address sender,
        uint256 id,
        bytes calldata newData
    ) external view returns (bool);

    /**
     * @notice Returns whether token manager can be swapped for another one by invocator
     * @notice Default token manager implementations should ignore id
     * @param sender Swapper
     * @param id Token grouping id (token id or edition id)
     * @param newTokenManager New token manager being swapped to
     * @return If invocation can swap token managers
     */
    function canSwap(
        address sender,
        uint256 id,
        address newTokenManager
    ) external view returns (bool);

    /**
     * @notice Returns whether token manager can be removed
     * @notice Default token manager implementations should ignore id
     * @param sender Swapper
     * @param id Token grouping id (token id or edition id)
     * @return If invocation can remove token manager
     */
    function canRemoveItself(address sender, uint256 id) external view returns (bool);
}