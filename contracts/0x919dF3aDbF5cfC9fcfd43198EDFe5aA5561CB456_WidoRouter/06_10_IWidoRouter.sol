// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.7;

interface IWidoRouter {
    /// @notice Order object describing the requirements of the zap
    /// @param user Address of user placing the order
    /// @param fromToken Address of the from token
    /// @param toToken Address of the to token
    /// @param fromTokenAmount Amount of the from token to spend on the user's behalf
    /// @param minToTokenAmount Minimum amount of the to token the user is willing to accept for this order
    /// @param nonce Number used once to ensure an order requested by a signature only executes once
    /// @param expiration Timestamp until which the order is valid to execute
    struct Order {
        address user;
        address fromToken;
        address toToken;
        uint256 fromTokenAmount;
        uint256 minToTokenAmount;
        uint32 nonce;
        uint32 expiration;
    }

    /// @notice Step object describing a single token transformation
    /// @param fromToken Address of the from token
    /// @param toToken Address of the to token
    /// @param targetAddress Address of the contract performing the transformation
    /// @param data Data which the swap contract will be called with
    /// @param amountIndex Index for the from token amount that can be found in data and needs to be updated with the most recent value.
    struct Step {
        address fromToken;
        address toToken;
        address targetAddress;
        bytes data;
        int32 amountIndex;
    }

    function verifyOrder(
        Order calldata order,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (bool);

    function executeOrder(
        Order calldata order,
        Step[] calldata route,
        uint256 feeBps,
        address partner
    ) external payable returns (uint256 toTokenBalance);

    function executeOrder(
        Order calldata order,
        Step[] calldata route,
        address recipient,
        uint256 feeBps,
        address partner
    ) external payable returns (uint256 toTokenBalance);

    function executeOrderWithSignature(
        Order calldata order,
        Step[] calldata route,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 feeBps,
        address partner
    ) external returns (uint256 toTokenBalance);
}