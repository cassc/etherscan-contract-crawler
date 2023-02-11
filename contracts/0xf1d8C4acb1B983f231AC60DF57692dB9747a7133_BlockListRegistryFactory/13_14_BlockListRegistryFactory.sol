// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

/**
 *     ____        _ __    __   ____  _ ________                     __
 *    / __ )__  __(_) /___/ /  / __ \(_) __/ __/__  ________  ____  / /_
 *   / __  / / / / / / __  /  / / / / / /_/ /_/ _ \/ ___/ _ \/ __ \/ __/
 *  / /_/ / /_/ / / / /_/ /  / /_/ / / __/ __/  __/ /  /  __/ / / / /_
 * /_____/\__,_/_/_/\__,_/  /_____/_/_/ /_/  \___/_/   \___/_/ /_/\__/
 */

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Clones} from "openzeppelin/proxy/Clones.sol";
import {BlockListRegistry} from "./BlockListRegistry.sol";

/// @title BlockListFactory
/// @notice contract factory to deploy blocklist registries.
/// @author transientlabs.xyz

contract BlockListRegistryFactory is Ownable {
    /*//////////////////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////////////////*/

    event BlockListRegistryCreated(address indexed creator, address indexed template, address indexed registryAddress);

    /*//////////////////////////////////////////////////////////////////////////
                                  Public State Variables
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Address of the current blocklist registry template.
    address public blockListRegistryTemplate;

    /*//////////////////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////////////////*/
    constructor(address initRegistryTemplate) Ownable() {
        blockListRegistryTemplate = initRegistryTemplate;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            Admin Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Update the address of the blocklist registry template used.
    /// @param newBlockListRegistryTemplate Address of template to be used by clones.
    /// @dev Must be contract owner to call.
    function setBlockListRegistryTemplate(address newBlockListRegistryTemplate) external onlyOwner {
        blockListRegistryTemplate = newBlockListRegistryTemplate;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          Public Write Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a new blocklist registry with an initial list that can be added to later.
    /// @param initBlockList Initial list to active on the blocklist registry.
    /// @return address with the registry address
    function createBlockListRegistry(address[] calldata initBlockList) external returns(address) {
        address registry = Clones.clone(blockListRegistryTemplate);
        BlockListRegistry(registry).initialize(msg.sender, initBlockList);
        emit BlockListRegistryCreated(msg.sender, blockListRegistryTemplate, registry);
        return registry;
    }
}