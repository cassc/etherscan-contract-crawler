//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Ownership interface
/// @author Amit Molek
interface IOwnership {
    /// @return The ownership units `member` owns
    function ownershipUnits(address member) external view returns (uint256);

    /// @return The total ownership units targeted by the group members
    function totalOwnershipUnits() external view returns (uint256);

    /// @return The total ownership units owned by the group members
    function totalOwnedOwnershipUnits() external view returns (uint256);

    /// @return true if the group members owns all the targeted ownership units
    function isCompletelyOwned() external view returns (bool);

    /// @return the smallest ownership unit
    function smallestOwnershipUnit() external view returns (uint256);

    /// @return true if `account` is a member
    function isMember(address account) external view returns (bool);

    /// @return an array with all the group's members
    function members() external view returns (address[] memory);

    /// @return the address of the member at `index`
    function memberAt(uint256 index) external view returns (address, uint256);

    /// @return how many members this group has
    function memberCount() external view returns (uint256);
}