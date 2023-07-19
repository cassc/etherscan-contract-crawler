// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.6;

contract ExclusionList {
    event ExclusionAdded(address indexed excludedAddress);
    event ExclusionRemoved(address indexed RemovedAddress);

    address internal constant SENTINEL_EXCLUSIONS = address(0x1);

    // Mapping of excluded addresses
    mapping(address => address) internal exclusions;

    function setupExclusions() internal {
        require(
            exclusions[SENTINEL_EXCLUSIONS] == address(0),
            "setUpModules has already been called"
        );
        exclusions[SENTINEL_EXCLUSIONS] = SENTINEL_EXCLUSIONS;
    }

    /// @dev Removes an excluded address
    /// @param prevExclusion Exclusion that pointed to the exclusion to be removed in the linked list
    /// @param exclusion Exclusion to be removed
    /// @notice This can only be called by the owner
    function _removeExclusion(address prevExclusion, address exclusion)
        internal
    {
        require(
            exclusion != address(0) && exclusion != SENTINEL_EXCLUSIONS,
            "Invalid exclusion"
        );
        require(
            exclusions[prevExclusion] == exclusion,
            "Exclusion already disabled"
        );
        exclusions[prevExclusion] = exclusions[exclusion];
        exclusions[exclusion] = address(0);
        emit ExclusionRemoved(exclusion);
    }

    function _excludeAddress(address exclusion) internal {
        require(
            exclusion != address(0) && exclusion != SENTINEL_EXCLUSIONS,
            "Invalid exclusion"
        );
        require(
            exclusions[exclusion] == address(0),
            "Exclusion already enabled"
        );
        exclusions[exclusion] = exclusions[SENTINEL_EXCLUSIONS];
        exclusions[SENTINEL_EXCLUSIONS] = exclusion;
        emit ExclusionAdded(exclusion);
    }

    /// @dev Returns if an exclusion is enabled
    /// @return True if the exclusion is enabled
    function isExcluded(address _exclusion) public view returns (bool) {
        return
            SENTINEL_EXCLUSIONS != _exclusion &&
            exclusions[_exclusion] != address(0);
    }

    /// @dev Returns array of exclusions.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of exclusions that should be returned.
    /// @return array Array of exclusions.
    /// @return next Start of the next page.
    function getExclusionsPaginated(address start, uint256 pageSize)
        public
        view
        returns (address[] memory array, address next)
    {
        // Init array with max page size
        array = new address[](pageSize);

        // Populate return array
        uint256 exclusionCount = 0;
        address currentExclusion = exclusions[start];
        while (
            currentExclusion != address(0x0) &&
            currentExclusion != SENTINEL_EXCLUSIONS &&
            exclusionCount < pageSize
        ) {
            array[exclusionCount] = currentExclusion;
            currentExclusion = exclusions[currentExclusion];
            exclusionCount++;
        }
        next = currentExclusion;
        // Set correct size of returned array
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(array, exclusionCount)
        }
    }
}