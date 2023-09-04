//SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.21;

/**
 * @title RMRK Wrap Registry
 * @notice This contract keeps track of the mapping between original and wrapped collections.
 */
interface IRMRKWrapRegistry {
    /**
     * @notice Returns the address of the wrapped collection corresponding to an original collection.
     * @param originalCollection The address of the original collection
     * @return wrappedCollection The address of the wrapped collection
     */
    function getWrappedCollection(
        address originalCollection
    ) external view returns (address wrappedCollection);

    /**
     * @notice Returns the address of the original collection corresponding to a wrapped collection.
     * @param wrappedCollection The address of the wrapped collection
     * @return originalCollection The address of the original collection
     */
    function getOriginalCollection(
        address wrappedCollection
    ) external view returns (address originalCollection);

    /**
     * @notice Maps an original collection to a wrapped collection.
     * @param original The address of the original collection
     * @param wrapped The address of the wrapped collection
     */
    function setOriginalAndWrappedCollection(
        address original,
        address wrapped
    ) external;

    /**
     * @notice Removes the mapping from original to wrapped collection. Removed collections can be retrieved through getPreviousWraps method.
     * @param original The address of the original collection
     */
    function removeWrappedCollection(address original) external;

    /**
     * @notice Returns the list of previous wraps for a collection.
     * @param original The address of the original collection
     * @return previousWraps The list of previous wraps
     */
    function getPreviousWraps(
        address original
    ) external view returns (address[] memory previousWraps);
}