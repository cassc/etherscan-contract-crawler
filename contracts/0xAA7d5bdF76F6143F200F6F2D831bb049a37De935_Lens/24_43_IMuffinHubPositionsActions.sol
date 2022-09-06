// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IMuffinHubPositionsActions {
    /// @notice                 Parameters for the mint function
    /// @param token0           Address of token0 of the pool
    /// @param token1           Address of token1 of the pool
    /// @param tierId           Position's tier index
    /// @param tickLower        Position's lower tick boundary
    /// @param tickUpper        Position's upper tick boundary
    /// @param liquidityD8      Amount of liquidity to mint, divided by 2^8
    /// @param recipient        Recipient's address
    /// @param positionRefId    Arbitrary reference id for the position
    /// @param senderAccRefId   Sender's account id
    /// @param data             Arbitrary data that is passed to callback function
    struct MintParams {
        address token0;
        address token1;
        uint8 tierId;
        int24 tickLower;
        int24 tickUpper;
        uint96 liquidityD8;
        address recipient;
        uint256 positionRefId;
        uint256 senderAccRefId;
        bytes data;
    }

    /// @notice                 Mint liquidity to a position
    /// @param params           MintParams struct
    /// @return amount0         Token0 amount to pay by the sender
    /// @return amount1         Token1 amount to pay by the sender
    function mint(MintParams calldata params) external returns (uint256 amount0, uint256 amount1);

    /// @notice                 Parameters for the burn function
    /// @param token0           Address of token0 of the pool
    /// @param token1           Address of token1 of the pool
    /// @param tierId           Tier index of the position
    /// @param tickLower        Lower tick boundary of the position
    /// @param tickUpper        Upper tick boundary of the position
    /// @param liquidityD8      Amount of liquidity to burn, divided by 2^8
    /// @param positionRefId    Arbitrary reference id for the position
    /// @param accRefId         Position owner's account id for receiving tokens
    /// @param collectAllFees   True to collect all accrued fees of the position
    struct BurnParams {
        address token0;
        address token1;
        uint8 tierId;
        int24 tickLower;
        int24 tickUpper;
        uint96 liquidityD8;
        uint256 positionRefId;
        uint256 accRefId;
        bool collectAllFees;
    }

    /// @notice                 Remove liquidity from a position
    /// @dev                    When removing partial liquidity and params.collectAllFees is set to false, partial fees
    ///                         are sent to position owner's account proportionally to the amount of liquidity removed.
    /// @param params           BurnParams struct
    /// @return amount0         Amount of token0 sent to the position owner account
    /// @return amount1         Amount of token1 sent to the position owner account
    /// @return feeAmount0      Amount of token0 fee sent to the position owner account
    /// @return feeAmount1      Amount of token1 fee sent to the position owner account
    function burn(BurnParams calldata params)
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 feeAmount0,
            uint256 feeAmount1
        );

    /// @notice                 Collect underlying tokens from a settled position
    /// @param params           BurnParams struct
    /// @return amount0         Amount of token0 sent to the position owner account
    /// @return amount1         Amount of token1 sent to the position owner account
    /// @return feeAmount0      Amount of token0 fee sent to the position owner account
    /// @return feeAmount1      Amount of token1 fee sent to the position owner account
    function collectSettled(BurnParams calldata params)
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 feeAmount0,
            uint256 feeAmount1
        );

    /// @notice                 Set a position's type, e.g. set to limit order
    /// @param token0           Address of token0 of the pool
    /// @param token1           Address of token1 of the pool
    /// @param tierId           Tier index of the position
    /// @param tickLower        Lower tick boundary of the position
    /// @param tickUpper        Upper tick boundary of the position
    /// @param positionRefId    Arbitrary reference id for the position
    /// @param limitOrderType   Direction of limit order (0: N/A; 1: zero for one; 2: one for zero)
    function setLimitOrderType(
        address token0,
        address token1,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper,
        uint256 positionRefId,
        uint8 limitOrderType
    ) external;

    /*===============================================================
     *                         GOVERNANCE
     *==============================================================*/

    /// @notice Update the governance address
    function setGovernance(address _governance) external;

    /// @notice Update pool's default tick spacing and protocol fee
    /// @param protocolFee Numerator of the % protocol fee (denominator is 255)
    function setDefaultParameters(uint8 tickSpacing, uint8 protocolFee) external;

    /// @notice Update pool's tick spacing and protocol fee
    /// @dev If setting a new tick spacing, the already initialized ticks that are not multiples of the new tick spacing
    /// will become unable to be added liquidity. To prevent this UX issue, the new tick spacing should better be a
    /// divisor of the old tick spacing.
    function setPoolParameters(
        bytes32 poolId,
        uint8 tickSpacing,
        uint8 protocolFee
    ) external;

    /// @notice Update a tier's swap fee and its tick spacing multiplier for limt orders
    function setTierParameters(
        bytes32 poolId,
        uint8 tierId,
        uint24 sqrtGamma,
        uint8 limitOrderTickSpacingMultiplier
    ) external;

    /// @notice Update the whitelist of swap fees which LPs can choose to create a pool
    function setDefaultAllowedSqrtGammas(uint24[] calldata sqrtGammas) external;

    /// @notice Update the pool-specific whitelist of swap fees
    function setPoolAllowedSqrtGammas(bytes32 poolId, uint24[] calldata sqrtGammas) external;

    /// @notice Update the pool-specific default tick spacing
    /// @param tickSpacing Tick spacing. Set to zero to unset the default.
    function setPoolDefaultTickSpacing(bytes32 poolId, uint8 tickSpacing) external;

    /// @notice Collect the protocol fee accrued
    function collectProtocolFee(address token, address recipient) external returns (uint256 amount);
}