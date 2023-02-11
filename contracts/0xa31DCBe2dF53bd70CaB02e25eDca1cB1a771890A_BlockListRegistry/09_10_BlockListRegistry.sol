// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

/**
 *     ____        _ __    __   ____  _ ________                     __
 *    / __ )__  __(_) /___/ /  / __ \(_) __/ __/__  ________  ____  / /_
 *   / __  / / / / / / __  /  / / / / / /_/ /_/ _ \/ ___/ _ \/ __ \/ __/
 *  / /_/ / /_/ / / / /_/ /  / /_/ / / __/ __/  __/ /  /  __/ / / / /_
 * /_____/\__,_/_/_/\__,_/  /_____/_/_/ /_/  \___/_/   \___/_/ /_/\__/
 */

import {ERC165Upgradeable} from "openzeppelin-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {OwnableAccessControlUpgradeable} from "tl-sol-tools/upgradeable/access/OwnableAccessControlUpgradeable.sol";
import {IBlockListRegistry} from "./IBlockListRegistry.sol";

/// @title BlockList
/// @notice abstract contract that can be inherited to block
///         approvals from non-royalty paying marketplaces
/// @author transientlabs.xyz
contract BlockListRegistry is IBlockListRegistry, OwnableAccessControlUpgradeable, ERC165Upgradeable {
    /*//////////////////////////////////////////////////////////////////////////
                                    Constants
    //////////////////////////////////////////////////////////////////////////*/
    bytes32 public constant BLOCK_LIST_ADMIN_ROLE = keccak256("BLOCK_LIST_ADMIN_ROLE");

    /*//////////////////////////////////////////////////////////////////////////
                               Private State Variables
    //////////////////////////////////////////////////////////////////////////*/

    uint256 private _c; // variable that allows reset for `_blockList`
    mapping(uint256 => mapping(address => bool)) private _blockList;

    /*//////////////////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////////////////*/

    /// @param disable - disable the initalizer on deployment
    constructor(bool disable) {
        if (disable) _disableInitializers();
    }

    /// @param newOwner - the initial owner of this contract
    /// @param initBlockList - initial list of addresses to add to the blocklist
    function initialize(address newOwner, address[] memory initBlockList) external initializer {
        uint256 len = initBlockList.length;
        for (uint8 i = 0; i < len; i++) {
            _setBlockListStatus(initBlockList[i], true);
        }
        __OwnableAccessControl_init(newOwner);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            Admin Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to clear the block list status
    /// @dev must be called by the blockList owner or admin
    /// @dev the blockList owner is likely the same as the owner of the token contract
    ///      but this could be different under certain applications. This implementation
    ///      makes no assumption of this though as it is standalone from the token contract.
    function clearBlockList() external onlyRoleOrOwner(BLOCK_LIST_ADMIN_ROLE) {
        _c++;
        emit BlockListCleared(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////////////////
                          Public Read Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to get blocklist status with True meaning that the operator is blocked
    /// @param operator - the address to check on the BlockList
    function getBlockListStatus(address operator) public view returns (bool) {
        return _getBlockListStatus(operator);
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IBlockListRegistry).interfaceId || super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                          Public Write Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to set the block list status for multiple operators
    /// @dev must be called by the blockList owner or admin
    /// @dev the blockList owner is likely the same as the owner of the token contract
    ///      but this could be different under certain applications. This implementation
    ///      makes no assumption of this though as it is standalone from the token contract.
    function setBlockListStatus(address[] calldata operators, bool status)
        external
        onlyRoleOrOwner(BLOCK_LIST_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < operators.length; i++) {
            _setBlockListStatus(operators[i], status);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice internal function to get blockList status
    /// @param operator - the address for which to get the BlockList status
    function _getBlockListStatus(address operator) internal view returns (bool) {
        return _blockList[_c][operator];
    }

    /// @notice internal function to set blockList status for one operator
    /// @param operator - address to set the status for
    /// @param status - True means add to the BlockList
    function _setBlockListStatus(address operator, bool status) internal {
        _blockList[_c][operator] = status;
        emit BlockListStatusChange(msg.sender, operator, status);
    }
}