// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./HDT/interfaces/IHDT.sol";
import "./BasePoolConfig.sol";
import "./BaseFeeManager.sol";

contract BasePoolStorage {
    uint256 internal constant HUNDRED_PERCENT_IN_BPS = 10000;
    uint256 internal constant SECONDS_IN_A_DAY = 1 days;
    /// A multiplier over the credit limit, which is up to 80% of the invoice amount,
    /// that determines whether a payment amount should be flagged for review.
    /// It is possible for the actual invoice payment is higher than the invoice amount,
    /// however, it is too high, the chance for a fraud is high and thus requires review.
    uint256 internal constant REVIEW_MULTIPLIER = 5;

    enum PoolStatus {
        Off,
        On
    }

    // The ERC20 token this pool manages
    IERC20 internal _underlyingToken;

    // The HDT token for this pool
    IHDT internal _poolToken;

    BasePoolConfig internal _poolConfig;

    // Reference to HumaConfig. Removed immutable since Solidity disallow reference it in the constructor,
    // but we need to retrieve the poolDefaultGracePeriod in the constructor.
    HumaConfig internal _humaConfig;

    // Reference to the fee manager contract
    BaseFeeManager internal _feeManager;

    // The amount of underlying token belongs to lenders
    uint256 internal _totalPoolValue;

    // Tracks the last deposit time for each lender in this pool
    mapping(address => uint256) internal _lastDepositTime;

    // Whether the pool is ON or OFF
    PoolStatus internal _status;

    // The addresses that are allowed to lend to this pool. Configurable only by the pool owner
    mapping(address => bool) internal _approvedLenders;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[100] private __gap;
}