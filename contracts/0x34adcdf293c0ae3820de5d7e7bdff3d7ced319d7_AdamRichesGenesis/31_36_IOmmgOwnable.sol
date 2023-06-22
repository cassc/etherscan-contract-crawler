// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title IOmmgProvenanceHash
/// @author NotAMeme aka nxlogixnick
/// @notice An interface for a custom implementation of Ownable contracts.
interface IOmmgOwnable {
    /// @dev Triggers when an unauthorized address attempts
    /// a restricted action
    /// @param account initiated the unauthorized action
    error OwnershipUnauthorized(address account);
    /// @dev Triggers when the ownership is transferred
    /// @param previousOwner the previous owner of the contract
    /// @param newOwner the new owner of the contract
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Returns the current owner address.
    /// @return owner the address of the current owner
    function owner() external view returns (address owner);

    /// @notice Leaves the contract without owner. It will not be possible to call
    /// `onlyOwner` functions anymore. Can only be called by the current owner.
    /// Triggers the {OwnershipTransferred} event.
    function renounceOwnershipPermanently() external;

    /// @notice Transfers the ownership to `newOwner`.
    /// Triggers the {OwnershipTransferred} event.
    /// `newOwner` can not be the zero address.
    /// @param newOwner the new owner of the contract
    function transferOwnership(address newOwner) external;
}