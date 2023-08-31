/// SPDX-License-Identifier: GPL-3.0

/// Copyright (C) 2023 Portals.fi

/// @author Portals.fi
/// @notice Interface for the Portals Multicall contract

pragma solidity 0.8.19;

interface IPortalsMulticall {
    /// @dev Describes a call to be executed in the aggregate function of PortalsMulticall.sol
    /// @param inputToken The token to sell
    /// @param target The target contract to call
    /// @param data The data to call the target contract with
    /// @param amountIndex The index of the quantity of inputToken in the data
    struct Call {
        address inputToken;
        address target;
        bytes data;
        uint256 amountIndex;
    }

    /// @dev Executes a series of calls in a single transaction
    /// @param calls An array of Call to execute
    function aggregate(Call[] calldata calls) external payable;
}