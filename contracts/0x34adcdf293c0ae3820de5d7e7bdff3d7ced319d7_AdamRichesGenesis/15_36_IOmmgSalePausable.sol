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

/// @title IOmmgSalePausable
/// @author NotAMeme aka nxlogixnick
/// @notice An interface for a simple mutable sale state on any contract
interface IOmmgSalePausable {
    error SaleNotActive();
    /// @notice This event gets triggered whenever the sale state changes
    /// @param newValue the new sale state
    event SaleIsActiveSet(bool newValue);

    /// @notice This function returns a boolean value indicating whether
    /// the public sale is currently active or not
    /// returns currentState whether the sale is active or not
    function saleIsActive() external view returns (bool currentState);

    /// @notice This function can be used to change the sale state to `newValue`.
    /// Triggers a {SaleIsActiveSet} event.
    /// @param newValue the desired new value for the sale state
    function setSaleIsActive(bool newValue) external;
}