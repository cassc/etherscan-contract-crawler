// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { AdapterType } from "@gearbox-protocol/integration-types/contracts/AdapterType.sol";

import { IACL } from "../IACL.sol";
import { IAddressProvider } from "../IAddressProvider.sol";
import { ICreditManagerV2 } from "../ICreditManagerV2.sol";

interface IAdapterExceptions {
    /// @notice Thrown when adapter tries to use a token that's not a collateral token of the connected Credit Manager
    error TokenNotAllowedException();

    /// @notice Thrown when caller of a `creditFacadeOnly` function is not the Credit Facade
    error CreditFacadeOnlyException();

    /// @notice Thrown when caller of a `configuratorOnly` function is not configurator
    error CallerNotConfiguratorException();
}

interface IAdapter is IAdapterExceptions {
    /// @notice Credit Manager the adapter is connected to
    function creditManager() external view returns (ICreditManagerV2);

    /// @notice Address of the contract the adapter is interacting with
    function targetContract() external view returns (address);

    /// @notice Address provider
    function addressProvider() external view returns (IAddressProvider);

    /// @notice ACL contract to check rights
    function _acl() external view returns (IACL);

    /// @notice Adapter type
    function _gearboxAdapterType() external pure returns (AdapterType);

    /// @notice Adapter version
    function _gearboxAdapterVersion() external pure returns (uint16);
}