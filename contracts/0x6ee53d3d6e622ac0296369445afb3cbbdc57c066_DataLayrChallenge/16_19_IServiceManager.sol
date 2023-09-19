// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IEigenLayrDelegation.sol";

/**
 * @title Interface for a `ServiceManager`-type contract.
 * @author Layr Labs, Inc.
 */
// TODO: provide more functions for this spec
interface IServiceManager {
    /// @notice Returns the current 'taskNumber' for the middleware
    function taskNumber() external view returns (uint32);

    /// @notice The Delegation contract of EigenLayer.
    function eigenLayrDelegation() external view returns (IEigenLayrDelegation);

    /// @notice Returns the `latestTime` until which operators must serve.
    function latestTime() external view returns (uint32);

    function owner() external view returns (address);
}