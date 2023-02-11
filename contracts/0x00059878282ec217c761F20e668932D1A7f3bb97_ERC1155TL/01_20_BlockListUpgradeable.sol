// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.17;

/// @title BlockList
/// @author transientlabs.xyz

/**
 *     ____        _ __    __   ____  _ ________                     __
 *    / __ )__  __(_) /___/ /  / __ \(_) __/ __/__  ________  ____  / /_
 *   / __  / / / / / / __  /  / / / / / /_/ /_/ _ \/ ___/ _ \/ __ \/ __/
 *  / /_/ / /_/ / / / /_/ /  / /_/ / / __/ __/  __/ /  /  __/ / / / /_
 * /_____/\__,_/_/_/\__,_/  /_____/_/_/ /_/  \___/_/   \___/_/ /_/\__/
 */

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {BlockedOperator, Unauthorized, IBlockList} from "./IBlockList.sol";
import {IBlockListRegistry} from "./IBlockListRegistry.sol";

/// @notice abstract contract that can be inherited to block
///         approvals from non-royalty paying marketplaces
abstract contract BlockListUpgradeable is Initializable, IBlockList {
    /*//////////////////////////////////////////////////////////////////////////
                                Public State Variables
    //////////////////////////////////////////////////////////////////////////*/

    IBlockListRegistry public blockListRegistry;

    /*//////////////////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////////////////*/

    event BlockListRegistryUpdated(address indexed caller, address indexed oldRegistry, address indexed newRegistry);

    /*//////////////////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev modifier that can be applied to approval functions in order to block listings on marketplaces
    modifier notBlocked(address operator) {
        if (getBlockListStatus(operator)) {
            revert BlockedOperator();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Initializer
    //////////////////////////////////////////////////////////////////////////*/

    /// @param blockListRegistryAddr - the initial BlockList Registry Address
    function __BlockList_init(address blockListRegistryAddr) internal onlyInitializing {
        __BlockList_init_unchained(blockListRegistryAddr);
    }

    /// @param blockListRegistryAddr - the initial BlockList Registry Address
    function __BlockList_init_unchained(address blockListRegistryAddr) internal onlyInitializing {
        blockListRegistry = IBlockListRegistry(blockListRegistryAddr);
        emit BlockListRegistryUpdated(msg.sender, address(0), blockListRegistryAddr);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            Admin Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to transfer ownership of the blockList
    /// @dev requires blockList owner
    /// @dev can be transferred to the ZERO_ADDRESS if desired
    /// @dev BE VERY CAREFUL USING THIS
    /// @param newBlockListRegistry - the address of the new BlockList registry
    function updateBlockListRegistry(address newBlockListRegistry) public {
        if (!isBlockListAdmin(msg.sender)) revert Unauthorized();

        address oldRegistry = address(blockListRegistry);
        blockListRegistry = IBlockListRegistry(newBlockListRegistry);
        emit BlockListRegistryUpdated(msg.sender, oldRegistry, newBlockListRegistry);
    }

    /*//////////////////////////////////////////////////////////////////////////
                          Public Read Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBlockList
    function getBlockListStatus(address operator) public view override returns (bool) {
        if (address(blockListRegistry).code.length == 0) return false;
        try blockListRegistry.getBlockListStatus(operator) returns (bool isBlocked) {
            return isBlocked;
        } catch {
            return false;
        }
    }

    /// @notice Abstract function to determine if the operator is a blocklist admin.
    /// @param potentialAdmin - the potential admin address to check
    function isBlockListAdmin(address potentialAdmin) public view virtual returns (bool);

    /*//////////////////////////////////////////////////////////////////////////
                                Upgradeability Gap
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev gap variable - see https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[50] private _gap;
}