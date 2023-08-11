// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IOperatorFilterRegistry} from "../../interfaces/IOperatorFilterRegistry.sol";

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title  UpdatableOperatorFilterStorage
 * @author slvrfn
 * @notice Library responsible for loading the associated "layout" from storage, and setting/retrieving
 *         the internal fields.
 */
library UpdatableOperatorFilterStorage {
    using UpdatableOperatorFilterStorage for UpdatableOperatorFilterStorage.Layout;

    bytes32 internal constant STORAGE_SLOT = keccak256("genesis.libraries.storage.UpdatableOperatorFilterStorage");

    struct Layout {
        IOperatorFilterRegistry operatorFilterRegistry;
    }

    /**
     * @notice Obtains the UpdatableOperatorFilterStorage layout from storage.
     * @dev    layout is stored at the chosen STORAGE_SLOT.
     */
    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev returns the current operator filter registry.
     */
    function _operatorFilterRegistry(Layout storage f) internal view returns (IOperatorFilterRegistry) {
        return f.operatorFilterRegistry;
    }

    /**
     * @dev updates the current operator filter registry.
     */
    function _setOperatorFilterRegistry(Layout storage f, IOperatorFilterRegistry registry) internal {
        f.operatorFilterRegistry = registry;
    }
}