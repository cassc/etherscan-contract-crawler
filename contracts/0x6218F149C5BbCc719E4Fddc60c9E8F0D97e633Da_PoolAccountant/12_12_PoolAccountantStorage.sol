// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract PoolAccountantStorageV1 {
    address public pool; // Address of Vesper pool
    uint256 public totalDebtRatio; // Total debt ratio. This will keep some buffer amount in pool
    uint256 public totalDebt; // Total debt. Sum of debt of all strategies.
    address[] public strategies; // Array of strategies
    address[] public withdrawQueue; // Array of strategy in the order in which funds should be withdrawn.
}

abstract contract PoolAccountantStorageV2 is PoolAccountantStorageV1 {
    struct StrategyConfig {
        bool active;
        uint256 interestFee; // Obsolete in favor of universal fee
        uint256 debtRate; // Obsolete
        uint256 lastRebalance; // Timestamp of last rebalance. It is used in universal fee calculation
        uint256 totalDebt; // Total outstanding debt strategy has
        uint256 totalLoss; // Total loss that strategy has realized
        uint256 totalProfit; // Total gain that strategy has realized
        uint256 debtRatio; // % of asset allocation
        uint256 externalDepositFee; // External deposit fee of strategy
    }

    mapping(address => StrategyConfig) public strategy; // Strategy address to its configuration

    uint256 public externalDepositFee; // External deposit fee of Vesper pool
}