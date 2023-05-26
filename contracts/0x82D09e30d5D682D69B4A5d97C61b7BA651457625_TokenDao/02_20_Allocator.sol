// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title Token Allocator contract
/// Role can be permanently burned
contract Allocator is Ownable {
    address private _allocator;
    bool private _allocatorBurned = false;

    event AllocatorRoleTransferred(address indexed previousAllocato, address indexed newAllocator);
    event AllocatorRoleBurned(address indexed previousAllocator);

    /**
     * @dev Permanently burns the allocator role.
     */
    function burnAllocatorRole() public virtual onlyOwner returns (address) {
        address oldAllocator = _allocator;
        _allocator = address(0);
        _allocatorBurned = true;

        emit AllocatorRoleBurned(oldAllocator);
        return oldAllocator;
    }

    /**
     * @dev Returns the address of the current allocator.
     */
    function allocatorRole() public view virtual returns (address) {
        return _allocator;
    }

    /**
     * @dev Returns the burn status of the current allocator.
     */
    function allocatorRoleBurned() public view virtual returns (bool) {
        return _allocatorBurned;
    }

    /**
     * @dev Transfers ownership of allocation to a new account (`newAllocator`).
     * Can only be called by the current owner.
     */
    function transferAllocationRole(address newAllocator) public virtual onlyOwner {
        require(!_allocatorBurned, "Allocator: Allocator role is burned");
        require(newAllocator != address(0), "Allocator: new allocator is the zero address");

        address oldAllocator = _allocator;
        _allocator = newAllocator;

        emit AllocatorRoleTransferred(oldAllocator, newAllocator);
    }
}