// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.6.12 <=0.8.13; // solhint-disable-line compiler-version

interface IConvexSiloWrapper {
    /// @dev Function to checkpoint single user rewards. This function has the same use case as the `user_checkpoint`
    ///     in `ConvexStakingWrapper` and implemented to match the `IConvexSiloWrapper` interface.
    /// @param _account address
    function checkpointSingle(address _account) external;

    /// @dev Function to checkpoint pair of users rewards. This function must be used to checkpoint collateral transfer.
    /// @param _from sender address
    /// @param _to recipient address
    function checkpointPair(address _from, address _to) external;

    /// @notice wrap underlying tokens
    /// @param _amount of underlying token to wrap
    /// @param _to receiver of the wrapped tokens
    function deposit(uint256 _amount, address _to) external;

    /// @dev initializeSiloWrapper executes parent `initialize` function, transfers ownership to Silo DAO,
    ///     changes token name and symbol. After `initializeSiloWrapper` execution, execution of the parent `initialize`
    ///     function is not possible. This function must be called by `ConvexSiloWrapperFactory` in the same
    ///     transaction with the deployment of this contract. If the parent `initialize` function was already executed
    ///     for some reason, call to `initialize` is skipped.
    /// @param _poolId the Curve pool id in the Convex Booster.
    function initializeSiloWrapper(uint256 _poolId) external;

    /// @notice unwrap and receive underlying tokens
    /// @param _amount of tokens to unwrap
    function withdrawAndUnwrap(uint256 _amount) external;

    /// @dev Function to init or update Silo address. Saves the history of deprecated Silos and routers to not take it
    ///     into account for rewards calculation. Reverts if the first Silo is not created yet. Note, that syncSilo
    ///     updates collateral vault and it can cause the unclaimed and not checkpointed rewards to be lost in
    ///     deprecated Silos. This behaviour is intended. Taking into account deprecated Silos shares for rewards
    ///     calculations will significantly increase the gas costs for all interactions with Convex Silo. Users should
    ///     claim rewards before the Silo is replaced. Note that replacing Silo is improbable scenario and must be done
    ///     by the DAO only in very specific cases.
    function syncSilo() external;

    /// @dev Function to get underlying curveLP token address. Created for a better naming,
    ///     the `curveToken` inherited variable name can be misleading.
    function underlyingToken() external view returns (address);
}