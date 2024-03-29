// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

import "../external/univ3/INonfungiblePositionManager.sol";
import "../oracles/IOracle.sol";
import "./IVaultGovernance.sol";
import "./IUniV3VaultConfigurable.sol";

interface IUniV3VaultConfigurableGovernance is IVaultGovernance {
    /// @notice Params that could be changed by Protocol Governance with Protocol Governance delay.
    /// @param positionManager Reference to UniV3 INonfungiblePositionManager
    struct DelayedProtocolParams {
        INonfungiblePositionManager positionManager;
        IOracle oracle;
    }

    /// @notice Delayed Protocol Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    function delayedProtocolParams() external view returns (DelayedProtocolParams memory);

    /// @notice Delayed Protocol Params staged for commit after delay.
    function stagedDelayedProtocolParams() external view returns (DelayedProtocolParams memory);

    /// @notice Stage Delayed Protocol Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    /// @param params New params
    function stageDelayedProtocolParams(DelayedProtocolParams calldata params) external;

    /// @notice Commit Delayed Protocol Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    function commitDelayedProtocolParams() external;

    /// @notice Deploys a new vault.
    /// @param vaultTokens_ ERC20 tokens that will be managed by this Vault
    /// @param owner_ Owner of the vault NFT
    /// @param fee_ Fee of the UniV3 pool
    /// @param uniV3Helper_ address of helper for UniV3 arithmetic with ticks
    /// @param safetyIndicesSet_ a bitmask used to determine which oracles are used in tvl calculation
    function createVault(
        address[] memory vaultTokens_,
        address owner_,
        uint24 fee_,
        address uniV3Helper_,
        uint256 safetyIndicesSet_
    ) external returns (IUniV3VaultConfigurable vault, uint256 nft);
}