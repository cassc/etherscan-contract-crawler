// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "../external/notional/interfaces/IWrappedfCashFactory.sol";

/// @title Fixed rate product vault view functions interface
/// @notice Describes view functions
interface IFRPViewer {
    /// @notice Number of supported maturities
    /// @return Returns number of supported maturities
    function SUPPORTED_MATURITIES() external view returns (uint8);

    /// @notice Base point number
    /// @return Returns base point number
    function BP() external view returns (uint16);

    /// @notice AUM scaled per seconds rate
    /// @return Returns AUM scaled per seconds rate
    function AUM_SCALED_PER_SECONDS_RATE() external view returns (uint);

    /// @notice Minting fee in basis point format [0 - 10_000]
    /// @return Returns minting fee in base point (BP) format
    function MINTING_FEE_IN_BP() external view returns (uint);

    /// @notice Burning fee in base point format [0 - 10_000]
    /// @return Returns burning fee in base point (BP) format
    function BURNING_FEE_IN_BP() external view returns (uint);

    /// @notice Maximum loss allowed during harvesting and withdrawal
    /// @return Returns maximum loss allowed during harvesting and withdrawal
    function maxLoss() external view returns (uint16);

    /// @notice Currency id of asset on Notional
    /// @return Returns currency id of the asset in the vault
    function currencyId() external view returns (uint16);

    /// @notice Address of Notional router
    /// @return Returns address of main Notional router contract
    function notionalRouter() external view returns (address);

    /// @notice Address of wrappedfCash factory
    /// @return Returns address of wrappedfCashFactory
    function wrappedfCashFactory() external view returns (IWrappedfCashFactory);

    /// @notice fCash positions that the vault has
    /// @return Returns addresses of fCash positions that the vault has
    function getfCashPositions() external view returns (address[2] memory);
}