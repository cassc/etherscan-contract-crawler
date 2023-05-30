//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// @title ITPLMechRentalManager
/// @author CyberBrokers
/// @author dev by @dievardump
/// @notice Interface for the TPLMechRentalManager
interface ITPLMechRentalManager {
    /// @notice Allows the TPLMech contract to check the current Transfer policy when an mech is already rented by `user`
    /// @dev having the Transfer while in rental policy externalised from TPLMech allows to update the Policy over time
    /// @param operator the operator requesting the Transfer
    /// @param from the account the token comes from
    /// @param to the account the token is going to
    /// @param tokenId the token id
    /// @param user the current user renting the item.
    /// @return if the current policy allows to transfer the item or not
    function checkTransferPolicy(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        address user
    ) external view returns (bool);

    /// @notice Allows an account to start the rental of `tokenId` until `expires`
    /// @param tokenId the item the user is currently renting
    /// @param expires until when the account wants to rent the item
    function rentMech(uint256 tokenId, uint64 expires) external payable;

    /// @notice Allows the current renter of a token to cancel their current Rental
    /// @param tokenId the item the user is currently renting
    function cancelRental(uint256 tokenId) external payable;
}