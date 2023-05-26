// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title OwnableTokenAccessControl
/// @notice Basic access control for utility tokens 
/// @author ponky
contract OwnableTokenAccessControl is Ownable {
    /// @dev Keeps track of how many accounts have been granted each type of access
    uint96 private _accessCounts;

    mapping (address => uint256) private _accessFlags;

    /// @dev Access types
    enum Access { Mint, Burn, Transfer, Claim }

    /// @dev Emitted when `account` is granted `access`.
    event AccessGranted(bytes32 indexed access, address indexed account);

    /// @dev Emitted when `account` is revoked `access`.
    event AccessRevoked(bytes32 indexed access, address indexed account);

    /// @dev Helper constants for fitting each access index into _accessCounts
    uint constant private _AC_BASE          = 4;
    uint constant private _AC_MASK_BITSIZE  = 1 << _AC_BASE;
    uint constant private _AC_DISABLED      = (1 << (_AC_MASK_BITSIZE - 1));
    uint constant private _AC_MASK_COUNT    = _AC_DISABLED - 1;

    /// @dev Convert the string `access` to an uint
    function _accessToIndex(bytes32 access) internal pure virtual returns (uint index) {
        if (access == 'MINT')       {return uint(Access.Mint);}
        if (access == 'BURN')       {return uint(Access.Burn);}
        if (access == 'TRANSFER')   {return uint(Access.Transfer);}
        if (access == 'CLAIM')      {return uint(Access.Claim);}
        revert("Access type does not exist");
    }

    function _hasAccess(Access access, address account) internal view returns (bool) {
        return (_accessFlags[account] & (1 << uint(access))) != 0;
    }

    function hasAccess(bytes32 access, address account) public view returns (bool) {
        uint256 flag = 1 << _accessToIndex(access);        
        return (_accessFlags[account] & flag) != 0;
    }

    function grantAccess(bytes32 access, address account) external onlyOwner {
        require(account.code.length > 0, "Can only grant access to a contract");

        uint index = _accessToIndex(access);
        uint256 flags = _accessFlags[account];
        uint256 newFlags = flags | (1 << index);
        require(flags != newFlags, "Account already has access");
        _accessFlags[account] = newFlags;

        uint shift = index << _AC_BASE;
        uint256 accessCount = _accessCounts >> shift;
        require((accessCount & _AC_DISABLED) == 0, "Granting this access is permanently disabled");
        require((accessCount & _AC_MASK_COUNT) < _AC_MASK_COUNT, "Access limit reached");
        unchecked {
            _accessCounts += uint96(1 << shift);
        }
        emit AccessGranted(access, account);
    }

    function revokeAccess(bytes32 access, address account) external onlyOwner {
        uint index = _accessToIndex(access);
        uint256 flags = _accessFlags[account];
        uint256 newFlags = flags & ~(1 << index);
        require(flags != newFlags, "Account does not have access");
        _accessFlags[account] = newFlags;

        uint shift = index << _AC_BASE;
        unchecked {
            _accessCounts -= uint96(1 << shift);
        }

        emit AccessRevoked(access, account);
    }

    /// @dev Returns the number of contracts that have `access`.
    function countOfAccess(bytes32 access) external view returns (uint256 accessCount) {
        uint index = _accessToIndex(access);

        uint shift = index << _AC_BASE;
        accessCount = (_accessCounts >> shift) & _AC_MASK_COUNT;
    }

    /// @dev `access` can still be revoked but not granted
    function permanentlyDisableGrantingAccess(bytes32 access) external onlyOwner {
        uint index = _accessToIndex(access);
        
        uint shift = index << _AC_BASE;
        uint256 flag = _AC_DISABLED << shift;
        uint256 accessCounts = _accessCounts;
        require((accessCounts & flag) == 0, "Granting this access is already disabled");
        _accessCounts = uint96(accessCounts | flag);
    }
}