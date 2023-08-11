// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;
pragma experimental ABIEncoderV2;

/** @notice Named Constants for defining max exposure state */
enum MaxExposure { Number, Pct }

/**
 * @title Interface for setting deposit invest limit for DeFi adapters except Curve
 * @author Opty.fi
 * @notice Interface of the DeFi protocol adapter for setting invest limit for deposit
 * @dev Abstraction layer to different DeFi protocols like AaveV1, Compound etc except Curve.
 * It is used as an interface layer for setting max invest limit and its type in number or percentage for DeFi adapters
 */
interface IAdapterInvestLimit {
    /**
     * @notice Notify when Max Deposit Protocol mode is set
     * @param maxDepositProtocolMode Mode of maxDeposit set (can be absolute value or percentage)
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogMaxDepositProtocolMode(MaxExposure indexed maxDepositProtocolMode, address indexed caller);

    /**
     * @notice Notify when Max Deposit Protocol percentage is set
     * @param maxDepositProtocolPct Protocol's max deposit percentage (in basis points, For eg: 50% means 5000)
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogMaxDepositProtocolPct(uint256 indexed maxDepositProtocolPct, address indexed caller);

    /**
     * @notice Notify when Max Deposit Pool percentage is set
     * @param maxDepositPoolPct Liquidity pool's max deposit percentage (in basis points, For eg: 50% means 5000)
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogMaxDepositPoolPct(uint256 indexed maxDepositPoolPct, address indexed caller);

    /**
     * @notice Notify when Max Deposit Amount is set
     * @param maxDepositAmount Absolute max deposit amount in underlying set for the given liquidity pool
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogMaxDepositAmount(uint256 indexed maxDepositAmount, address indexed caller);

    /**
     * @notice Sets the absolute max deposit value in underlying for the given liquidity pool
     * @param _liquidityPool liquidity pool address for which to set max deposit value (in absolute value)
     * @param _underlyingToken address of underlying token
     * @param _maxDepositAmount absolute max deposit amount in underlying to be set for given liquidity pool
     */
    function setMaxDepositAmount(
        address _liquidityPool,
        address _underlyingToken,
        uint256 _maxDepositAmount
    ) external;

    /**
     * @notice Sets the percentage of max deposit value for the given liquidity pool
     * @param _liquidityPool liquidity pool address
     * @param _maxDepositPoolPct liquidity pool's max deposit percentage (in basis points, For eg: 50% means 5000)
     */
    function setMaxDepositPoolPct(address _liquidityPool, uint256 _maxDepositPoolPct) external;

    /**
     * @notice Sets the percentage of max deposit protocol value
     * @param _maxDepositProtocolPct protocol's max deposit percentage (in basis points, For eg: 50% means 5000)
     */
    function setMaxDepositProtocolPct(uint256 _maxDepositProtocolPct) external;

    /**
     * @notice Sets the type of investment limit
     *                  1. Percentage of pool value
     *                  2. Amount in underlying token
     * @dev Types (can be number or percentage) supported for the maxDeposit value
     * @param _mode Mode of maxDeposit to be set (can be absolute value or percentage)
     */
    function setMaxDepositProtocolMode(MaxExposure _mode) external;
}