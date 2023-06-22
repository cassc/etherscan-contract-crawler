// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.6;

/// @title   Interface of ManagerBase contract
/// @author  Primitive
interface IManagerBase {
    /// ERRORS ///

    /// @notice Thrown when the sender is not a Primitive Engine contract
    error NotEngineError();

    /// @notice Thrown when the constructor parameters are wrong
    error WrongConstructorParametersError();

    /// VIEW FUNCTIONS ///

    /// @notice Returns the address of the factory
    function factory() external view returns (address);

    /// @notice Returns the address of WETH9
    function WETH9() external view returns (address);

    /// @notice Returns the address of the PositionDescriptor
    function positionDescriptor() external view returns (address);
}