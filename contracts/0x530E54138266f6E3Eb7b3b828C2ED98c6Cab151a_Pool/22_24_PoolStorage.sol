// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/utils/structs/EnumerableSet.sol";
import "../lib/MappedEnumerableSet.sol";
import "../interfaces/IPool.sol";

abstract contract PoolStorageV1 is IPool {
    struct LiquidationFees {
        uint128 liquidatorFee;
        uint128 protocolFee;
    }

    /**
     * @notice The debt floor (in USD) for each synthetic token
     * This parameters is used to keep incentive for liquidators (i.e. cover gas and provide enough profit)
     */
    uint256 public debtFloorInUsd;

    /**
     * @notice The fee charged when depositing collateral
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    uint256 public depositFee;

    /**
     * @notice The fee charged when minting a synthetic token
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    uint256 public issueFee;

    /**
     * @notice The fee charged when withdrawing collateral
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    uint256 public withdrawFee;

    /**
     * @notice The fee charged when repaying debt
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    uint256 public repayFee;

    /**
     * @notice The fee charged when swapping synthetic tokens
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    uint256 public swapFee;

    /**
     * @notice The fees charged when liquidating a position
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    LiquidationFees public liquidationFees;

    /**
     * @notice The max percent of the debt allowed to liquidate
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    uint256 public maxLiquidable;

    /**
     * @notice PoolRegistry
     */
    IPoolRegistry public poolRegistry;

    /**
     * @notice Swap feature on/off flag
     */
    bool public isSwapActive;

    /**
     * @notice Treasury contract
     */
    ITreasury public treasury;

    /**
     * @notice Represents collateral's deposits
     */
    EnumerableSet.AddressSet internal depositTokens;

    /**
     * @notice Get the deposit token's address from given underlying asset
     */
    mapping(IERC20 => IDepositToken) public depositTokenOf;

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
    IRewardsDistributor[] internal rewardsDistributors;

    /**
     * @notice Get the debt token's address from given synthetic asset
     */
    mapping(ISyntheticToken => IDebtToken) public debtTokenOf;
}