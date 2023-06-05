//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "./IPermissionItems.sol";

struct UserProxy {
    address user;
    address proxy;
}

/**
 * @title Interface for PermissionManager
 * @author Swarm
 * @dev Provide tier based permissions assignments and revoking functions.
 */
interface IPermissionManagerV2 is IAccessControlUpgradeable {
    /// @notice mapping of Security Tokens, entered by token Address
    function securityTokens(address token) external view returns (uint256);

    /// @notice last security token id public variable
    function lastSecurityTokenId() external view returns (bool);

    /**
     * @dev Emitted when `permissionItems` address is set.
     */
    event PermissionItemsSet(IPermissionItems indexed newPermissions);

    /**
     * @dev Emitted when new security token id is generated
     */
    event NewSecurityTokenIdGenerated(uint256 indexed newId, address indexed tokenContract);

    /**
     * @dev Emitted when lastSecurityTokenId was edited
     */
    event LastSecurityTokenIdEdited(uint256 indexed oldId, uint256 indexed newId, address indexed caller);

    /**
     * @dev Grants PERMISSIONS_ADMIN_ROLE to `_permissionsAdmin`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     * - `_permissionsAdmin` should not be the zero address.
     */
    function setPermissionsAdmin(address _permissionsAdmin) external;

    /**
     * @dev Sets `_permissionItems` as the new permissionItems module.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_permissionItems` should not be the zero address.
     *
     * @param _permissionItems The address of the new Pemissions module.
     */
    function setPermissionItems(IPermissionItems _permissionItems) external returns (bool);

    /**
     * @dev Assigns Tier1 permission to the `_account`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_account` address should not have Tier1 already assigned.
     * - `_account` address should not be zero address.
     *
     * @param _account The address to assign Tier1.
     */
    function assignTier1(address _account) external;

    /**
     * @dev Assigns Tier1 permission to the list `_accounts`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - each address in `_accounts` should not have Tier1 already assigned.
     * - `_accounts` addresses should not be zero addresses.
     *
     * @param _accounts The addresses to assign Tier1.
     */
    function assignTiers1(address[] calldata _accounts) external;

    /**
     * @dev Removes Tier1 permission from the `_account`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_account` should have Tier1 assigned.
     * - `_account` should not be a zero address.
     *
     * @param _account The address to revoke Tier1.
     */
    function revokeTier1(address _account) external;

    /**
     * @dev Removes Tier1 permission from the list `_accounts`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - each address in `_accounts` should have Tier1 assigned.
     * - each address in `_accounts` should not be a zero address.
     *
     * @param _accounts The addresses to revoke Tier1.
     */
    function revokeTiers1(address[] calldata _accounts) external;

    /**
     * @dev Assigns Tier2 permission to users and proxies.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - Address in `_userProxy.user` should not have Tier2 already assigned.
     * - Address in `_userProxy.proxy` should not have Tier2 already assigned.
     * - Address in `_userProxy.user` should not be zero address.
     *
     * @param _userProxy The address of user and proxy.
     */
    function assignTier2(UserProxy calldata _userProxy) external;

    /**
     * @dev Assigns Tier2 permission to a list of users and proxies.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - All user addresses in `_usersProxies` should not have Tier2 already assigned.
     * - All proxy addresses in `_usersProxies` should not have Tier2 already assigned.
     * - All `_userProxy.user` addresses should not be zero address.
     *
     * @param _usersProxies The addresses of the users and proxies.
     *                      An array of the struct UserProxy where user and proxy are bout required.
     */
    function assignTiers2(UserProxy[] calldata _usersProxies) external;

    /**
     * @dev Removes Tier2 permission from user and proxy.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_userProxy.user` should have Tier2 assigned.
     * - `_userProxy.proxy` should have Tier2 assigned.
     *
     * @param _userProxy The address of user and proxy.
     */
    function revokeTier2(UserProxy calldata _userProxy) external;

    /**
     * @dev Removes Tier2 permission from a list of users and proxies.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - All user addresses in `_usersProxies` should have Tier2 assigned.
     * - All proxy addresses in should have Tier2 assigned.
     *
     * @param _usersProxies The addresses of the users and proxies.
     *                      An array of the struct UserProxy where user and proxy are bout required.
     */
    function revokeTiers2(UserProxy[] calldata _usersProxies) external;

    /**
     * @dev Assigns SoF token permission to the `_account`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_account` address should not have SoF token already assigned.
     * - `_account` address should not be zero address.
     *
     * @param _account The address to assign SoF token.
     */
    function assignSoFToken(address _account) external;

    /**
     * @dev Assigns SoF tokens permission to the list `_accounts`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - each address in `_accounts` should not have SoF token already assigned.
     * - `_accounts` addresses should not be zero addresses.
     *
     * @param _accounts The addresses to assign SoF tokens.
     */
    function assignSoFTokens(address[] calldata _accounts) external;

    /**
     * @dev Removes SoF token permission from the `_account`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_account` should have SoF token assigned.
     * - `_account` should not be a zero address.
     *
     * @param _account The address to revoke SoF token.
     */
    function revokeSoFToken(address _account) external;

    /**
     * @dev Removes SoF tokens permission from the list `_accounts`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - each address in `_accounts` should have SoF token assigned.
     * - each address in `_accounts` should not be a zero address.
     *
     * @param _accounts The addresses to revoke SoF tokens.
     */
    function revokeSoFTokens(address[] calldata _accounts) external;

    /**
     * @dev Suspends permissions effects to user and proxy.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - Address in `_userProxy.user` should not be already suspended.
     * - Address in `_userProxy.proxy` should not be already suspended.
     * - Address in `_userProxy.user` should not be zero address.
     *
     * @param _userProxy The address of user and proxy.
     */
    function suspendUser(UserProxy calldata _userProxy) external;

    /**
     * @dev Suspends permissions effects to a list of users and proxies.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - All user addresses in `_usersProxies` should not be already suspended.
     * - All proxy addresses in `_usersProxies` should not be already suspended.
     * - All user addresses in `_usersProxies` should not be a zero address.
     *
     * @param _usersProxies The addresses of the users and proxies.
     *                      An array of the struct UserProxy where is required
     *                      but proxy can be optional if it is set to zero address.
     */
    function suspendUsers(UserProxy[] calldata _usersProxies) external;

    /**
     * @dev Re-activates pemissions effects for user and proxy.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_userProxy.user` should be suspended.
     * - `_userProxy.proxy` should be suspended.
     *
     * @param _userProxy The address of user and proxy.
     */
    function unsuspendUser(UserProxy calldata _userProxy) external;

    /**
     * @dev Re-activates pemissions effects on a list of users and proxies.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - All user addresses in `_usersProxies` should be suspended.
     * - All proxy addresses in `_usersProxies` should be suspended.
     *
     * @param _usersProxies The addresses of the users and proxies.
     *                      An array of the struct UserProxy where is required
     *                      but proxy can be optional if it is set to zero address.
     */
    function unsuspendUsers(UserProxy[] calldata _usersProxies) external;

    /**
     * @dev Assigns Reject permission to user and proxy.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - Address in `_userProxy.user` should not be already rejected.
     * - Address in `_userProxy.proxy` should not be already rejected.
     * - Address in `_userProxy.user` should not be zero address.
     *
     *
     * @param _userProxy The address of user and proxy.
     */
    function rejectUser(UserProxy calldata _userProxy) external;

    /**
     * @dev Assigns Reject permission to a list of users and proxies.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - All user addresses in `_usersProxies` should not be already rejected.
     * - All proxy addresses in `_usersProxies` should not be already rejected.
     * - All user addresses in `_usersProxies` should not be a zero address.
     *
     *
     * @param _usersProxies The addresses of the users and proxies.
     *                      An array of the struct UserProxy where is required
     *                      but proxy can be optional if it is set to zero address.
     */
    function rejectUsers(UserProxy[] calldata _usersProxies) external;

    /**
     * @dev Removes Reject permission from user and proxy.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_userProxy.user` should be rejected.
     * - `_userProxy.proxy` should be rejected.
     *
     *
     * @param _userProxy The address of user and proxy.
     */
    function unrejectUser(UserProxy calldata _userProxy) external;

    /**
     * @dev Removes Reject permission from a list of users and proxies.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - All user addresses in `_usersProxies` should be rejected.
     * - All proxy addresses in `_usersProxies` should be rejected.
     *
     *
     * @param _usersProxies The addresses of the users and proxies.
     *                      An array of the struct UserProxy where is required
     *                      but proxy can be optional if it is set to zero address.
     */
    function unrejectUsers(UserProxy[] calldata _usersProxies) external;

    /**
     * @dev Assigns specific item `_itemId` to the `_account`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_account` should not have `_itemId` already assigned.
     * - `_account` should not be address zero.
     *
     * @param _itemId Item to be assigned.
     * @param _account The address to assign Tier1.
     */
    function assignSingleItem(uint256 _itemId, address _account) external;

    /**
     * @dev Assigns specific item `_itemId` to the list `_accounts`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - each address in `_accounts` should not have `_itemId` already assigned.
     * - each address in `_accounts` should not be zero address.
     *
     * @param _itemId Item to be assigned.
     * @param _accounts The addresses to assign Tier1.
     */
    function assignItem(uint256 _itemId, address[] calldata _accounts) external;

    /**
     * @dev Removes specific item `_itemId` from `_account`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_accounts` should have `_itemId` already assigned.
     *
     * @param _itemId Item to be removed
     * @param _account The address to assign Tier1.
     */
    function removeSingleItem(uint256 _itemId, address _account) external;

    /**
     * @dev Removes specific item `_itemId` to the list `_accounts`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - each address in `_accounts` should have `_itemId` already assigned.
     *
     * @param _itemId Item to be removed
     * @param _accounts The addresses to assign Tier1.
     */
    function removeItem(uint256 _itemId, address[] calldata _accounts) external;

    /**
     * @dev Returns `true` if `_account` has been assigned Tier1 permission.
     *
     * @param _account The address of the user.
     */
    function hasTier1(address _account) external view returns (bool);

    /**
     * @dev Returns `true` if `_account` has been assigned Tier2 permission.
     *
     * @param _account The address of the user.
     */
    function hasTier2(address _account) external view returns (bool);

    /**
     * @dev Returns `true` if `_account` has been assigned SoF token permission.
     *
     * @param _account The address of the user.
     */
    function hasSoFToken(address _account) external view returns (bool);

    /**
     * @dev Returns `true` if `_account` has been Suspended.
     *
     * @param _account The address of the user.
     */
    function isSuspended(address _account) external view returns (bool);

    /**
     * @dev Returns `true` if `_account` has been Rejected.
     *
     * @param _account The address of the user.
     */
    function isRejected(address _account) external view returns (bool);

    /**
     * @dev Sets the counter for the new 1155 ID
     *
     * @param _newId The new 1155 ID to start from
     */
    function editLastSecurityTokenId(uint256 _newId) external;

    /**
     * @dev Get the 1155 ID from the token address
     *
     * @param _tokenContract The address of the token to get the 1155 ID from
     */
    function getSecurityTokenId(address _tokenContract) external view returns (uint256);

    /**
     * @dev Generates the new 1155 ID for the token contract
     *
     * @param _tokenContract The address of the token to generate the 1155 ID
     */
    function generateSecurityTokenId(address _tokenContract) external returns (uint256);

    /**
     * @dev Check if the account has 1155 ID
     *
     * @param _user The account to check
     * @param _itemId The ID of the 1155 token
     * @return bool true if the account has such ID
     */
    function hasSecurityToken(address _user, uint256 _itemId) external view returns (bool);

    /**
     * @dev Check if the account has 1155 token(item)
     *
     * @param _user The account to check
     * @param _itemId The ID of the 1155 token
     * @return bool true if the account has such ID
     */
    function hasItem(address _user, uint256 _itemId) external view returns (bool);
}