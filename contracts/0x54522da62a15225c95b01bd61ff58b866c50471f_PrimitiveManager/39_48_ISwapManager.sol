// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.6;

import "@primitivefi/rmm-core/contracts/interfaces/callback/IPrimitiveSwapCallback.sol";

/// @title   Interface of SwapManager contract
/// @author  Primitive
interface ISwapManager is IPrimitiveSwapCallback {
    /// @notice                Parameters for the swap function
    /// @param recipient       Address of the recipient
    /// @param risky           Address of the risky token
    /// @param stable          Address of the stable token
    /// @param poolId          Id of the pool
    /// @param riskyForStable  True if swapping risky for stable
    /// @param deltaIn         Exact amount to send
    /// @param deltaOut        Exact amount to receive
    /// @param fromMargin      True if the sent amount should be taken from the margin
    /// @param toMargin        True if the received amount should be sent to the margin
    /// @param deadline        Transaction will revert above this deadline
    struct SwapParams {
        address recipient;
        address risky;
        address stable;
        bytes32 poolId;
        bool riskyForStable;
        uint256 deltaIn;
        uint256 deltaOut;
        bool fromMargin;
        bool toMargin;
        uint256 deadline;
    }

    /// ERRORS ///

    /// @notice Thrown when the deadline is reached
    error DeadlineReachedError();

    /// EVENTS ///

    /// @notice                Emitted when a swap occurs
    /// @param payer           Address of the payer
    /// @param recipient       Address of the recipient
    /// @param engine          Address of the engine
    /// @param poolId          Id of the pool
    /// @param riskyForStable  True if swapping risky for stable
    /// @param deltaIn         Sent amount
    /// @param deltaOut        Received amount
    /// @param fromMargin      True if the sent amount is taken from the margin
    /// @param toMargin        True if the received amount is sent to the margin
    event Swap(
        address indexed payer,
        address recipient,
        address indexed engine,
        bytes32 indexed poolId,
        bool riskyForStable,
        uint256 deltaIn,
        uint256 deltaOut,
        bool fromMargin,
        bool toMargin
    );

    /// EFFECTS FUNCTIONS ///

    /// @notice        Swaps an exact amount of risky OR stable tokens for some risky OR stable tokens
    /// @dev           Funds are swapped from a specific pool located into a specific engine
    /// @param params  A struct of type SwapParameters
    function swap(SwapParams calldata params) external payable;
}