// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ICommonErrors} from "./ICommonErrors.sol";

interface IControllable is ICommonErrors {
    /// @notice The dependency with the given `name` is invalid.
    error InvalidDependency(bytes32 name);

    /// @notice Get controller address.
    /// @return Controller address.
    function controller() external returns (address);

    /// @notice Set a named dependency to the given contract address.
    /// @param _name bytes32 name of the dependency to set.
    /// @param _contract address of the dependency.
    function setDependency(bytes32 _name, address _contract) external;
}