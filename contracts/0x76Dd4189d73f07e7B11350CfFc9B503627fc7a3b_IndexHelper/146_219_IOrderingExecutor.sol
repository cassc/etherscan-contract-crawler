// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "../libraries/ValidatorLibrary.sol";

import "./IOrdererV2.sol";

/// @title Ordering Executor interface
/// @notice Contains signature verification and order execution logic
interface IOrderingExecutor {
    /// @notice Pause order execution
    function pause() external;

    /// @notice Unpause order execution
    function unpause() external;

    /// @notice Sets minimum amount of signers required to sign an order
    /// @param _minAmountOfSigners Minimum amount of signers required to sign an order
    function setMinAmountOfSigners(uint256 _minAmountOfSigners) external;

    /// @notice Swap shares internally
    /// @param _signs List of signatures
    /// @param _info Swap info object
    function internalSwap(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.InternalSwapV2 calldata _info) external;

    /// @notice Swap shares using DEX
    /// @param _signs List of signatures
    /// @param _info Swap info object
    function externalSwap(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.ExternalSwapV2 calldata _info) external;

    /// @notice Index registry address
    /// @return Returns index registry address
    function registry() external view returns (address);

    /// @notice Nonce of signer
    /// @return Returns nonce of given signer
    function nonce() external view returns (uint256);

    /// @notice Minimum amount of signers required to sign an order
    /// @return Returns minimum amount of signers required to sign an order
    function minAmountOfSigners() external view returns (uint256);
}