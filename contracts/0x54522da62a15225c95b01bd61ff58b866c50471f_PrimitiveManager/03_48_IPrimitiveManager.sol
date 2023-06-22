// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.6;

import "@primitivefi/rmm-core/contracts/interfaces/callback/IPrimitiveCreateCallback.sol";
import "@primitivefi/rmm-core/contracts/interfaces/callback/IPrimitiveLiquidityCallback.sol";

/// @title   Interface of PrimitiveManager contract
/// @author  Primitive
interface IPrimitiveManager is IPrimitiveCreateCallback, IPrimitiveLiquidityCallback {
    /// ERRORS ///

    /// @notice  Thrown when trying to add or remove zero liquidity
    error ZeroLiquidityError();

    /// @notice  Thrown when the received liquidity is lower than the expected
    error MinLiquidityOutError();

    /// @notice  Thrown when the received risky / stable amounts are lower than the expected
    error MinRemoveOutError();

    /// EVENTS ///

    /// @notice               Emitted when a new pool is created
    /// @param payer          Payer sending liquidity
    /// @param engine         Primitive Engine where the pool is created
    /// @param poolId         Id of the new pool
    /// @param strike         Strike of the new pool
    /// @param sigma          Sigma of the new pool
    /// @param maturity       Maturity of the new pool
    /// @param gamma          Gamma of the new pool
    /// @param delLiquidity   Amount of liquidity allocated (minus the minimum liquidity)
    event Create(
        address indexed payer,
        address indexed engine,
        bytes32 indexed poolId,
        uint128 strike,
        uint32 sigma,
        uint32 maturity,
        uint32 gamma,
        uint256 delLiquidity
    );

    /// @notice              Emitted when liquidity is allocated
    /// @param payer         Payer sending liquidity
    /// @param recipient     Address that receives minted ERC-1155 Primitive liquidity tokens
    /// @param engine        Primitive Engine receiving liquidity
    /// @param poolId        Id of the pool receiving liquidity
    /// @param delLiquidity  Amount of liquidity allocated
    /// @param delRisky      Amount of risky tokens allocated
    /// @param delStable     Amount of stable tokens allocated
    /// @param fromMargin    True if liquidity was paid from margin
    event Allocate(
        address payer,
        address indexed recipient,
        address indexed engine,
        bytes32 indexed poolId,
        uint256 delLiquidity,
        uint256 delRisky,
        uint256 delStable,
        bool fromMargin
    );

    /// @notice              Emitted when liquidity is removed
    /// @param payer         Payer receiving liquidity
    /// @param engine        Engine where liquidity is removed from
    /// @param poolId        Id of the pool where liquidity is removed from
    /// @param delLiquidity  Amount of liquidity removed
    /// @param delRisky      Amount of risky tokens allocated
    /// @param delStable     Amount of stable tokens allocated
    event Remove(
        address indexed payer,
        address indexed engine,
        bytes32 indexed poolId,
        uint256 delLiquidity,
        uint256 delRisky,
        uint256 delStable
    );

    /// EFFECT FUNCTIONS ///

    /// @notice              Creates a new pool using the specified parameters
    /// @param risky         Address of the risky asset
    /// @param stable        Address of the stable asset
    /// @param strike        Strike price of the pool to calibrate to, with the same decimals as the stable token
    /// @param sigma         Volatility to calibrate to as an unsigned 256-bit integer w/ precision of 1e4, 10000 = 100%
    /// @param maturity      Maturity timestamp of the pool, in seconds
    /// @param gamma         Multiplied against swap in amounts to apply fee, equal to 1 - fee %, an unsigned 32-bit integer, w/ precision of 1e4, 10000 = 100%
    /// @param riskyPerLp    Risky reserve per liq. with risky decimals, = 1 - N(d1), d1 = (ln(S/K)+(r*sigma^2/2))/sigma*sqrt(tau)
    /// @param delLiquidity  Amount of liquidity to allocate to the curve, wei value with 18 decimals of precision
    /// @return poolId       Id of the new created pool (Keccak256 hash of the engine address, maturity, sigma and strike)
    /// @return delRisky     Amount of risky tokens allocated into the pool
    /// @return delStable    Amount of stable tokens allocated into the pool
    function create(
        address risky,
        address stable,
        uint128 strike,
        uint32 sigma,
        uint32 maturity,
        uint32 gamma,
        uint256 riskyPerLp,
        uint256 delLiquidity
    )
        external
        payable
        returns (
            bytes32 poolId,
            uint256 delRisky,
            uint256 delStable
        );

    /// @notice               Allocates liquidity into a pool
    /// @param recipient      Address that receives minted ERC-1155 Primitive liquidity tokens
    /// @param poolId         Id of the pool
    /// @param risky          Address of the risky asset
    /// @param stable         Address of the stable asset
    /// @param delRisky       Amount of risky tokens to allocate
    /// @param delStable      Amount of stable tokens to allocate
    /// @param fromMargin     True if the funds of the sender should be used
    /// @return delLiquidity  Amount of liquidity allocated into the pool
    function allocate(
        address recipient,
        bytes32 poolId,
        address risky,
        address stable,
        uint256 delRisky,
        uint256 delStable,
        bool fromMargin,
        uint256 minLiquidityOut
    ) external payable returns (uint256 delLiquidity);

    /// @notice              Removes liquidity from a pool
    /// @param engine        Address of the engine
    /// @param poolId        Id of the pool
    /// @param delLiquidity  Amount of liquidity to remove
    /// @param minRiskyOut   Minimum amount of risky tokens expected to be received
    /// @param minStableOut  Minimum amount of stable tokens expected to be received
    /// @return delRisky     Amount of risky tokens removed from the pool
    /// @return delStable    Amount of stable tokens removed from the pool
    function remove(
        address engine,
        bytes32 poolId,
        uint256 delLiquidity,
        uint256 minRiskyOut,
        uint256 minStableOut
    ) external returns (uint256 delRisky, uint256 delStable);
}