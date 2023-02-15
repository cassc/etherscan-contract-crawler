// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title This interface is specific for Frigg-implemented tokens
/// @author Frigg team
interface IFrigg {
    /// @notice For PrimaryRouter.sol to conduct primary buy logic at issuance
    function mint(address account, uint256 amount) external;

    /// @notice For PrimaryRouter.sol to conduct primary sell logic at expiry
    function burn(address account, uint256 amount) external;

    /// @notice Returns if primary market is opened.
    function isPrimaryMarketActive() external view returns (bool);

    /// @notice Returns if the bond has expired and the issuer starts to conduct buyback.
    function seeBondExpiryStatus() external view returns (bool);

    /// @notice A getter function for dApps or third parties to fetch the terms and conditions
    function termsURL() external view returns (string memory);
}