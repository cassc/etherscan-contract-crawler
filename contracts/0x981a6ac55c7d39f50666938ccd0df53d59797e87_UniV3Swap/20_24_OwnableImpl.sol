// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title Ownable Implementation
/// @author 0xSplits
/// @notice Ownable clone-implementation
abstract contract OwnableImpl {
    error Unauthorized();

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    /// -----------------------------------------------------------------------
    /// storage - mutables
    /// -----------------------------------------------------------------------

    /// slot 0 - 12 bytes free

    address internal $owner;
    /// 20 bytes

    /// -----------------------------------------------------------------------
    /// constructor & initializer
    /// -----------------------------------------------------------------------

    constructor() {}

    function __initOwnable(address owner_) internal virtual {
        emit OwnershipTransferred(address(0), owner_);
        $owner = owner_;
    }

    /// -----------------------------------------------------------------------
    /// modifiers
    /// -----------------------------------------------------------------------

    modifier onlyOwner() virtual {
        if (msg.sender != owner()) revert Unauthorized();
        _;
    }

    /// -----------------------------------------------------------------------
    /// functions - public & external - onlyOwner
    /// -----------------------------------------------------------------------

    function transferOwnership(address owner_) public virtual onlyOwner {
        $owner = owner_;
        emit OwnershipTransferred(msg.sender, owner_);
    }

    /// -----------------------------------------------------------------------
    /// functions - public & external - view
    /// -----------------------------------------------------------------------

    function owner() public view virtual returns (address) {
        return $owner;
    }
}