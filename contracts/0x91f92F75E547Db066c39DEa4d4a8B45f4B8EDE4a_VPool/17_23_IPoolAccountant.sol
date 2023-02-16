// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPoolAccountant {
    function decreaseDebt(address strategy_, uint256 decreaseBy_) external;

    function migrateStrategy(address old_, address new_) external;

    function reportEarning(
        address strategy_,
        uint256 profit_,
        uint256 loss_,
        uint256 payback_
    ) external returns (uint256 _actualPayback, uint256 _creditLine);

    function reportLoss(address strategy_, uint256 loss_) external;

    function availableCreditLimit(address strategy_) external view returns (uint256);

    function excessDebt(address strategy_) external view returns (uint256);

    function getStrategies() external view returns (address[] memory);

    function getWithdrawQueue() external view returns (address[] memory);

    function strategy(
        address strategy_
    )
        external
        view
        returns (
            bool _active,
            uint256 _interestFee, // Obsolete
            uint256 _debtRate, // Obsolete
            uint256 _lastRebalance,
            uint256 _totalDebt,
            uint256 _totalLoss,
            uint256 _totalProfit,
            uint256 _debtRatio,
            uint256 _externalDepositFee
        );

    function externalDepositFee() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function totalDebtOf(address strategy_) external view returns (uint256);

    function totalDebtRatio() external view returns (uint256);
}