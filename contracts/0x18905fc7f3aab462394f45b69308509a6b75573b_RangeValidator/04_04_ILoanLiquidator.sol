// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

/// @title Liquidates Collateral for Defaulted Loans
/// @author Florida St
/// @notice It liquidates collateral corresponding to defaulted loans
///         and sends back the proceeds to the vault.
interface ILoanLiquidator {
    /// @notice Given a loan, it takes posession of the NFT and liquidates it.
    /// @param _loanId The loan id.
    /// @param _contract The loan contract address.
    /// @param _tokenId The NFT id.
    /// @param _asset The asset address.
    /// @param _duration The liquidation duration.
    /// @param _originator The address that trigger the liquidation.
    function liquidateLoan(
        uint256 _loanId,
        address _contract,
        uint256 _tokenId,
        address _asset,
        uint96 _duration,
        address _originator
    ) external;
}