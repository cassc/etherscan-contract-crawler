// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

interface IVault {
    struct StrategyParams {
        uint256 activation;
        uint256 last_report;
        uint256 current_debt;
        uint256 max_debt;
    }

    function asset() external view returns (address _asset);

    function decimals() external view returns (uint256);

    // HashMap that records all the strategies that are allowed to receive assets from the vault
    function strategies(
        address _strategy
    ) external view returns (StrategyParams memory _params);

    // Current assets held in the vault contract. Replacing balanceOf(this) to avoid price_per_share manipulation
    function total_idle() external view returns (uint256);

    function update_debt(
        address strategy,
        uint256 target_debt
    ) external returns (uint256);
}