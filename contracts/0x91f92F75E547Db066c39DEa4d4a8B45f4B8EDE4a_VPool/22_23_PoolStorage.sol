// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../dependencies/openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/vesper/IVesperPool.sol";

abstract contract PoolStorageV1 is IVesperPool {
    ///@notice Collateral token address
    IERC20 public token;
    /// @notice PoolAccountant address
    address public poolAccountant;
    /// @notice PoolRewards contract address
    address public poolRewards;
    address private feeWhitelistObsolete; // Obsolete in favor of AddressSet of feeWhitelist
    address private keepersObsolete; // Obsolete in favor of AddressSet of keepers
    address private maintainersObsolete; // Obsolete in favor of AddressSet of maintainers
    address private feeCollectorObsolete; // Fee collector address. Obsolete as there is no fee to collect
    uint256 private withdrawFeeObsolete; // Withdraw fee for this pool. Obsolete in favor of universal fee
    uint256 private decimalConversionFactorObsolete; // It can be used in converting value to/from 18 decimals
    bool internal withdrawInETH; // This flag will be used by VETH pool as switch to withdraw ETH or WETH
}

abstract contract PoolStorageV2 is PoolStorageV1 {
    EnumerableSet.AddressSet private _feeWhitelistObsolete; // Obsolete in favor of universal fee
    EnumerableSet.AddressSet internal _keepers; // List of keeper addresses
    EnumerableSet.AddressSet internal _maintainers; // List of maintainer addresses
}

abstract contract PoolStorageV3 is PoolStorageV2 {
    /// @notice Universal fee of this pool. Default to 2%
    uint256 public universalFee = 200;
    /// @notice Maximum percentage of profit that can be counted as universal fee. Default to 50%
    uint256 public maxProfitAsFee = 5_000;
    /// @notice Minimum deposit limit.
    /// @dev Do not set it to 0 as deposit() is checking if amount >= limit
    uint256 public minDepositLimit = 1;
}