// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "../Validator.sol";

/// @title IValidatorFactory.
/// @author 2021 ShardLabs
interface IValidatorFactory {
    /// @notice Deploy a new validator proxy contract.
    /// @return return the address of the deployed contract.
    function create() external returns (address);

    /// @notice Remove a validator proxy from the validators.
    function remove(address _validatorProxy) external;

    /// @notice Set the node operator contract address.
    function setOperator(address _operator) external;

    /// @notice Set validator implementation contract address.
    function setValidatorImplementation(address _validatorImplementation)
        external;
}