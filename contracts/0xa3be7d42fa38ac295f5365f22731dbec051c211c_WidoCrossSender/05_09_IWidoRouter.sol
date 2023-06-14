// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.7;

import "../WidoTokenManager.sol";

interface IWidoRouter {
    /// @notice OrderInput object describing the desired token inputs
    /// @param tokenAddress Address of the input token
    /// @param fromTokenAmount Amount of the input token to spend on the user's behalf
    /// @dev amount must == msg.value when token == address(0)
    struct OrderInput {
        address tokenAddress;
        uint256 amount;
    }

    /// @notice OrderOutput object describing the desired token outputs
    /// @param tokenAddress Address of the output token
    /// @param minOutputAmount Minimum amount of the output token the user is willing to accept for this order
    struct OrderOutput {
        address tokenAddress;
        uint256 minOutputAmount;
    }

    /// @notice Order object describing the requirements of the zap
    /// @param inputs Array of input objects, see OrderInput
    /// @param outputs Array of output objects, see OrderOutput
    /// @param user Address of user placing the order
    /// @param nonce Number used once to ensure an order requested by a signature only executes once
    /// @param expiration Timestamp until which the order is valid to execute
    struct Order {
        OrderInput[] inputs;
        OrderOutput[] outputs;
        address user;
        uint32 nonce;
        uint32 expiration;
    }

    /// @notice Step object describing a single token transformation
    /// @param fromToken Address of the from token
    /// @param targetAddress Address of the contract performing the transformation
    /// @param data Data which the swap contract will be called with
    /// @param amountIndex Index for the from token amount that can be found in data and needs to be updated with the most recent value.
    struct Step {
        address fromToken;
        address targetAddress;
        bytes data;
        int32 amountIndex;
    }

    function widoTokenManager() external view returns (WidoTokenManager);

    function bank() external view returns (address);

    function verifyOrder(Order calldata order, uint8 v, bytes32 r, bytes32 s) external view returns (bool);

    function executeOrder(
        Order calldata order,
        Step[] calldata route,
        uint256 feeBps,
        address partner
    ) external payable;

    function executeOrder(
        Order calldata order,
        Step[] calldata route,
        address recipient,
        uint256 feeBps,
        address partner
    ) external payable;

    function executeOrderWithSignature(
        Order calldata order,
        Step[] calldata route,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 feeBps,
        address partner
    ) external;
}