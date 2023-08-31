// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title FriendsAndFamilyMinter Interface
/// @notice This interface defines the functions and events for the FriendsAndFamilyMinter contract.
interface IFriendsAndFamilyMinter {
    // Events
    error MissingDiscount();
    error ExistingDiscount();

    // Functions

    /// @dev Checks if the specified recipient has a discount.
    /// @param recipient The address of the recipient to check for the discount.
    /// @return A boolean indicating whether the recipient has a discount or not.
    function hasDiscount(address recipient) external view returns (bool);

    /// @dev Retrieves the address of the Cre8orsNFT contract used by the FriendsAndFamilyMinter.
    /// @return The address of the Cre8orsNFT contract.
    function cre8orsNFT() external view returns (address);

    /// @dev Retrieves the address of the MinterUtilities contract used by the FriendsAndFamilyMinter.
    /// @return The address of the MinterUtilities contract.
    function minterUtilityContractAddress() external view returns (address);

    /// @dev Retrieves the maximum number of tokens claimed for free by the specified recipient.
    /// @param recipient The address of the recipient to query for the maximum claimed free tokens.
    /// @return The maximum number of tokens claimed for free by the recipient.
    function totalClaimed(address recipient) external view returns (uint256);

    /// @dev Mints a new token for the specified recipient and returns the token ID.
    /// @param recipient The address of the recipient who will receive the minted token.
    /// @return The token ID of the minted token.
    function mint(address recipient) external returns (uint256);

    /// @dev Grants a discount to the specified recipient, allowing them to mint tokens without paying the regular price.
    /// @param recipient The address of the recipient who will receive the discount.
    function addDiscount(address recipient) external;

    /// @dev Grants a discount to the specified recipient, allowing them to mint tokens without paying the regular price.
    /// @param recipient The address of the recipients who will receive the discount.
    function addDiscount(address[] memory recipient) external;

    /// @dev Removes the discount from the specified recipient, preventing them from minting tokens with a discount.
    /// @param recipient The address of the recipient whose discount will be removed.
    function removeDiscount(address recipient) external;

    /// @dev Sets a new address for the MinterUtilities contract.
    /// @param _newMinterUtilityContractAddress The address of the new MinterUtilities contract.
    function setNewMinterUtilityContractAddress(
        address _newMinterUtilityContractAddress
    ) external;
}