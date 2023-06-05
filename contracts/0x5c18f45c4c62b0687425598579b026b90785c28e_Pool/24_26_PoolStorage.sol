// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/utils/structs/EnumerableSet.sol";
import "../lib/MappedEnumerableSet.sol";
import "../interfaces/IPool.sol";

// solhint-disable var-name-mixedcase, max-states-count
abstract contract PoolStorageV1 is IPool {
    /**
     * @notice The debt floor (in USD) for each synthetic token
     * This parameters is used to keep incentive for liquidators (i.e. cover gas and provide enough profit)
     */
    uint256 public override debtFloorInUsd;

    uint256 private depositFee__DEPRECATED;

    uint256 private issueFee__DEPRECATED;

    uint256 private withdrawFee__DEPRECATED;

    uint256 private repayFee__DEPRECATED;

    uint256 private swapFee__DEPRECATED;

    uint256 private liquidationFees__DEPRECATED;

    /**
     * @notice The max percent of the debt allowed to liquidate
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    uint256 public override maxLiquidable;

    /**
     * @notice PoolRegistry
     */
    IPoolRegistry public override poolRegistry;

    /**
     * @notice Swap feature on/off flag
     */
    bool public override isSwapActive;

    /**
     * @notice Treasury contract
     */
    ITreasury public override treasury;

    /**
     * @notice Represents collateral's deposits
     */
    EnumerableSet.AddressSet internal depositTokens;

    /**
     * @notice Get the deposit token's address from given underlying asset
     */
    mapping(IERC20 => IDepositToken) public override depositTokenOf;

    /**
     * @notice Available debt tokens
     */
    EnumerableSet.AddressSet internal debtTokens;

    /**
     * @notice Per-account deposit tokens (i.e. tokens that user has balance > 0)
     */
    MappedEnumerableSet.AddressSet internal depositTokensOfAccount;

    /**
     * @notice Per-account debt tokens (i.e. tokens that user has balance > 0)
     */
    MappedEnumerableSet.AddressSet internal debtTokensOfAccount;

    /**
     * @notice RewardsDistributor contracts
     */
    IRewardsDistributor[] internal rewardsDistributors__DEPRECATED;

    /**
     * @notice Get the debt token's address from given synthetic asset
     */
    mapping(ISyntheticToken => IDebtToken) public override debtTokenOf;
}

abstract contract PoolStorageV2 is PoolStorageV1 {
    /**
     * @notice Swapper contract
     */
    ISwapper public swapper;

    /**
     * @notice FeeProvider contract
     */
    IFeeProvider public override feeProvider;

    /**
     * @notice RewardsDistributor contracts
     */
    EnumerableSet.AddressSet internal rewardsDistributors;
}