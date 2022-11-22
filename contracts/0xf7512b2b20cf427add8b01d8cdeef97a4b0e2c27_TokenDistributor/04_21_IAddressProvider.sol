// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

/// @title Optimised for front-end Address Provider interface
interface IAddressProvider {
    /// @return Address of ACL contract
    function getACL() external view returns (address);

    /// @return Address of ContractsRegister
    function getContractsRegister() external view returns (address);

    /// @return Address of AccountFactory
    function getAccountFactory() external view returns (address);

    /// @return Address of DataCompressor
    function getDataCompressor() external view returns (address);

    /// @return Address of GEAR token
    function getGearToken() external view returns (address);

    /// @return Address of WETH token
    function getWethToken() external view returns (address);

    /// @return Address of WETH Gateway
    function getWETHGateway() external view returns (address);

    /// @return Address of PriceOracle
    function getPriceOracle() external view returns (address);

    /// @return Address of DAO Treasury Multisig
    function getTreasuryContract() external view returns (address);

    /// @return Address of PathFinder
    function getLeveragedActions() external view returns (address);
}