// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice Multi-role system managed by a singular owner with enums and bitmap packing
/// @dev inspired by OZ's AccessControl and Solmate's Owned
/// TODO: add supportsInterface compatibility
abstract contract Permissions {
    // default value for a guard that always rejects
    address constant MAX_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    /// @dev to remain backwards compatible, can only extend this list
    enum Operation {
        UPGRADE, // update proxy implementation & permits
        MINT, // mint new tokens
        BURN, // burn existing tokens
        TRANSFER, // transfer existing tokens
        RENDER // render nft metadata
    }

    /*============
        EVENTS
    ============*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);
    event Permit(address indexed account, bytes32 permissions);
    event Guard(Operation indexed operation, address indexed guard);

    /*=============
        STORAGE
    =============*/

    // primary superadmin of the contract
    address public owner;
    // accounts => 256 auth'd operations, each represented by their own bit
    mapping(address => bytes32) public permissionsOf;
    // Operation => Guard smart contract, applies additional invariant constraints per operation
    // address(0) represents no constraints, address(max) represents full constraints = not allowed
    mapping(Operation => address) public guardOf;

    /*=============
        OWNABLE
    =============*/

    function transferOwnership(address newOwner) external {
        require(owner == msg.sender, "NOT_PERMITTED");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /*=================
        PERMISSIONS
    =================*/

    // check if sender is owner or has the permission for the operation
    modifier permitted(Operation operation) {
        _checkPermit(operation);
        _;
    }

    /// @dev make internal function for modifier to reduce copied code when re-using modifier
    function _checkPermit(Operation operation) internal view {
        require(hasPermission(msg.sender, operation), "NOT_PERMITTED");
    }

    function hasPermission(address account, Operation operation) public view virtual returns (bool) {
        return owner == account || permissionsOf[account] & _operationBit(operation) != 0;
    }

    function permit(address account, bytes32 newPermissions) external permitted(Operation.UPGRADE) {
        _permit(account, newPermissions);
    }

    /// @dev setup module parameters atomically with enabling/disabling permissions
    function permitAndSetup(address account, bytes32 newPermissions, bytes calldata setupCall)
        external
        permitted(Operation.UPGRADE)
    {
        _permit(account, newPermissions);
        _setup(account, setupCall);
    }

    function _permit(address account, bytes32 newPermissions) internal {
        permissionsOf[account] = newPermissions;
        emit Permit(account, newPermissions);
    }

    function permissionsValue(Operation[] memory operations) external pure returns (bytes32 value) {
        for (uint256 i; i < operations.length; i++) {
            value |= _operationBit(operations[i]);
        }
    }

    function _operationBit(Operation operation) internal pure returns (bytes32) {
        return bytes32(1 << uint8(operation));
    }

    /*============
        GUARDS
    ============*/

    function guard(Operation operation, address newGuard) external permitted(Operation.UPGRADE) {
        _guard(operation, newGuard);
    }

    function guardAndSetup(Operation operation, address newGuard, bytes calldata setupCall)
        external
        permitted(Operation.UPGRADE)
    {
        _guard(operation, newGuard);
        _setup(newGuard, setupCall);
    }

    function _guard(Operation operation, address newGuard) internal {
        guardOf[operation] = newGuard;
        emit Guard(operation, newGuard);
    }

    function _setup(address account, bytes calldata data) internal {
        (bool success,) = account.call(data);
        require(success, "SETUP_FAILED");
    }
}