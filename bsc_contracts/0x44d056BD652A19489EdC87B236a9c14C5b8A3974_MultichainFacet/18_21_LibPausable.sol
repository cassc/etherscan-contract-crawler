// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {GenericErrors} from "./GenericErrors.sol";

library LibPausable {
    /// Types ///
    bytes32 internal constant NAMESPACE =
        keccak256("com.miraidon.library.pausable.management");

    /// Storage ///
    struct PausableStorage {
        mapping(address => bool) pausable;
    }

    /// Events ///
    event FacetPause(address indexed facet);
    event FacetUnpause(address indexed facet);

    /// @dev Fetch local storage
    function pausableStorage()
        internal
        pure
        returns (PausableStorage storage stor)
    {
        bytes32 position = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            stor.slot := position
        }
    }

    /**
     * @notice Pause a contract
     * @param facet The address of a facet
     */
    function pause(address facet) internal {
        require(facet != address(this), GenericErrors.E61);
        PausableStorage storage stor = pausableStorage();
        stor.pausable[facet] = true;
        emit FacetPause(facet);
    }

    /**
     * @notice Unpause a contract
     * @param facet The address of a facet
     */
    function unpause(address facet) internal {
        PausableStorage storage stor = pausableStorage();
        stor.pausable[facet] = false;
        emit FacetUnpause(facet);
    }

    /**
     * @notice Enforce contract not paused
     */
    function enforceNotPaused() internal view {
        address facet = LibDiamond
            .diamondStorage()
            .selectorToFacetAndPosition[msg.sig]
            .facetAddress;
        PausableStorage storage stor = pausableStorage();
        require(!stor.pausable[facet], GenericErrors.E60);
    }
}