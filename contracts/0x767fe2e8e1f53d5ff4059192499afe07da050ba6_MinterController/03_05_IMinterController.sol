// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

/// @dev responsible for registering minters with StanceRKLCollection
///      responsible for checking if particular Minter is allowed to mint token ids
///      responsible for managing token ids for StanceRKLCollection
interface IMinterController {
    error MinterZeroAddressNotAllowed();
    error MinterNotRegistered();
    error MinterNotAllowedForTokenId(uint256 requestedTokenId, uint256 allowedLowerBound, uint256 allowedUpperBound);
    error MinterAlreadyRegistered();
    error InvalidBounds(uint128 lowerBound, uint128 upperBound);

    /// @dev if only one token id is allowed, then lowerBound == upperBound
    ///      note that the bounds are inclusive, so lowerBound := 2 and
    ///      upperBound := 4 would mean that minter is allowed to mint token
    ///      ids 2, 3 and 4.
    struct MinterAllowedTokenIds {
        uint128 lowerBound;
        uint128 upperBound;
    }

    /// @dev minter is the address of the contract that implementes IMinter
    ///      throws MinterNotAllowedForTokenId
    function checkMinterAllowedForTokenIds(address minter, uint256[] memory tokenIds) external;

    /// @dev registers a new minter with StanceRKLCollection
    function registerMinter(address minter, MinterAllowedTokenIds calldata) external;
}