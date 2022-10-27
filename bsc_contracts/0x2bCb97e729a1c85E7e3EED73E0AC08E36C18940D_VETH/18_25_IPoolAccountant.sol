// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPoolAccountant {
    function decreaseDebt(address _strategy, uint256 _decreaseBy) external;

    function migrateStrategy(address _old, address _new) external;

    function reportEarning(
        address _strategy,
        uint256 _profit,
        uint256 _loss,
        uint256 _payback
    ) external returns (uint256 _actualPayback, uint256 _creditLine);

    function reportLoss(address _strategy, uint256 _loss) external;

    function availableCreditLimit(address _strategy) external view returns (uint256);

    function excessDebt(address _strategy) external view returns (uint256);

    function getStrategies() external view returns (address[] memory);

    function getWithdrawQueue() external view returns (address[] memory);

    function strategy(address _strategy)
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

    function totalDebtOf(address _strategy) external view returns (uint256);

    function totalDebtRatio() external view returns (uint256);
}