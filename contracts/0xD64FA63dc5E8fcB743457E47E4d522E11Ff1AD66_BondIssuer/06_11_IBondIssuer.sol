// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IBondController } from "./buttonwood/IBondController.sol";

interface IBondIssuer {
    /// @notice Event emitted when a new bond is issued by the issuer.
    /// @param bond The newly issued bond.
    event BondIssued(IBondController bond);

    /// @notice The address of the underlying collateral token to be used for issued bonds.
    /// @return Address of the collateral token.
    function collateral() external view returns (address);

    /// @notice Issues a new bond if sufficient time has elapsed since the last issue.
    function issue() external;

    /// @notice Checks if a given bond has been issued by the issuer.
    /// @param bond Address of the bond to check.
    /// @return if the bond has been issued by the issuer.
    function isInstance(IBondController bond) external view returns (bool);

    /// @notice Fetches the most recently issued bond.
    /// @return Address of the most recent bond.
    function getLatestBond() external returns (IBondController);

    /// @notice Returns the total number of bonds issued by this issuer.
    /// @return Number of bonds.
    function issuedCount() external view returns (uint256);

    /// @notice The bond address from the issued list by index.
    /// @return Address of the bond.
    function issuedBondAt(uint256 index) external view returns (IBondController);
}