// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { RolesAuthority } from './authorities/RolesAuthority.sol';

/**
 * @notice An abstract Auth that contracts in the Endaoment ecosystem can inherit from. It is based on
 * the `Auth.sol` contract from Solmate, but does not inherit from it. Most of the functionality
 * is either slightly different, or not needed. In particular:
 * - EndaomentAuth uses an initializer such that it can be deployed with minimal proxies.
 * - EndaomentAuth contracts reference a RolesAuthority, not just an Authority, when looking up permissions.
 *   In the Endaoment ecosystem, this is assumed to be the Registry.
 * - EndaomentAuth contracts do not have an owner, but instead grant ubiquitous permission to its RoleAuthority's
 *   owner. In the Endaoment ecosystem, this is assumed to be the board of directors multi-sig.
 * - EndaomentAuth contracts can optionally declare themselves a "special target" at deploy time. Instead of passing
 *   their address to the authority when looking up their permissions, they'll instead pass the special target bytes.
 *   See documentation on `specialTarget` for more information.
 *
 */
abstract contract EndaomentAuth {

    /// @notice Thrown when an account without proper permissions calls a privileged method.
    error Unauthorized();

    /// @notice Thrown if there is an attempt to deploy with address 0 as the authority.
    error InvalidAuthority();

    /// @notice Thrown if there is a second call to initialize.
    error AlreadyInitialized();

    /// @notice The contract used to source permissions for accounts targeting this contract.
    RolesAuthority public authority;

    /**
     * @notice If set to a non-zero value, this contract will pass these byes as the target contract
     * to the RolesAuthority's `canCall` method, rather than its own contract. This allows a single
     * RolesAuthority permission to manage permissions simultaneously for a group of contracts that
     * identify themselves as a certain type. For example: set a permission for all "entity" contracts.
     */
    bytes20 public specialTarget;

    /**
     * @notice One time method to be called at deployment to configure the contract. Required so EndaomentAuth
     * contracts can be deployed as minimal proxies (clones).
     * @param _authority Contract that will be used to source permissions for accounts targeting this contract.
     * @param _specialTarget The bytes that this contract will pass as the "target" when looking up permissions
     * from the authority. If set to empty bytes, this contract will pass its own address instead.
     */
    function __initEndaomentAuth(RolesAuthority _authority, bytes20 _specialTarget) internal virtual {
        if (address(_authority) == address(0)) revert InvalidAuthority();
        if (address(authority) != address(0)) revert AlreadyInitialized();
        authority = _authority;
        specialTarget = _specialTarget;
    }

    /**
     * @notice Modifier for methods that require authorization to execute.
     */
    modifier requiresAuth virtual {
        if(!isAuthorized(msg.sender, msg.sig)) revert Unauthorized();
        _;
    }

     /**
     * @notice Internal method that asks the authority whether the caller has permission to execute a method.
     * @param user The account attempting to call a permissioned method on this contract
     * @param functionSig The signature hash of the permissioned method being invoked.
     */
    function isAuthorized(address user, bytes4 functionSig) internal virtual view returns (bool) {
        RolesAuthority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.
        address _target = specialTarget == "" ? address(this) : address(specialTarget);

        // The caller has permission on authority, or the caller is the RolesAuthority owner
        return auth.canCall(user, _target, functionSig) || user == auth.owner();
    }
}