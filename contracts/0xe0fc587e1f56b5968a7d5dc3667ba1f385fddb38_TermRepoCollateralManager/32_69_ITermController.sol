//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @notice ITermController is an interface that defines events and functions of the Controller contract.
interface ITermController {
    // ========================================================================
    // = Interface/API ========================================================
    // ========================================================================

    /// @notice External view function which returns contract address of treasury wallet
    function getTreasuryAddress() external view returns (address);

    /// @notice External view function which returns contract address of protocol reserve
    function getProtocolReserveAddress() external view returns (address);

    /// @notice External view function which returns if contract address is a Term Finance contract or not
    /// @param contractAddress input contract address
    function isTermDeployed(
        address contractAddress
    ) external view returns (bool);

    // ========================================================================
    // = Admin Functions ======================================================
    // ========================================================================

    /// @notice Admin function to update the Term Finance treasury wallet address
    /// @param treasuryWallet    new treasury address
    function updateTreasuryAddress(address treasuryWallet) external;

    /// @notice Admin function to update the Term Finance protocol reserve wallet address
    /// @param protocolReserveAddress    new protocol reserve wallet address
    function updateProtocolReserveAddress(
        address protocolReserveAddress
    ) external;

    /// @notice Admin function to add a new Term Finance contract to Controller
    /// @param termContract    new term contract address
    function markTermDeployed(address termContract) external;

    /// @notice Admin function to remove a contract from Controller
    /// @param termContract    term contract address to remove
    function unmarkTermDeployed(address termContract) external;
}