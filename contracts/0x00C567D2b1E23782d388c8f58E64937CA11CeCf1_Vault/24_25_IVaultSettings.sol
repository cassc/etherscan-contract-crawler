// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

interface IVaultSettings {
    //
    // Events
    //

    event ImmediateInvestLimitPctUpdated(uint256 percentage);
    event InvestPctUpdated(uint256 percentage);
    event TreasuryUpdated(address indexed treasury);
    event PerfFeePctUpdated(uint16 pct);
    event StrategyUpdated(address indexed strategy);
    event LossTolerancePctUpdated(uint16 pct);

    /**
     * Update immediate invest limit percentage
     *
     * Emits {ImmediateInvestLimitPctUpdated} event
     *
     * @param _pct the new immediate invest limit percentage
     */
    function setImmediateInvestLimitPct(uint16 _pct) external;

    /**
     * Update invest percentage
     *
     * Emits {InvestPctUpdated} event
     *
     * @param _investPct the new invest percentage
     */
    function setInvestPct(uint16 _investPct) external;

    /**
     * Changes the treasury used by the vault.
     *
     * @param _treasury the new strategy's address.
     */
    function setTreasury(address _treasury) external;

    /**
     * Changes the performance fee used by the vault.
     *
     * @param _perfFeePct the new performance fee.
     */
    function setPerfFeePct(uint16 _perfFeePct) external;

    /**
     * Changes the strategy used by the vault.
     *
     * @notice if there is invested funds in previous strategy, it is not allowed to set new strategy.
     * @param _strategy the new strategy's address.
     */
    function setStrategy(address _strategy) external;

    /**
     * Changes the estimated investment fee used by the strategy.
     *
     * @param _pct the new investment fee estimated percentage.
     */
    function setLossTolerancePct(uint16 _pct) external;

    /**
     * Sets the minimum lock period for deposits.
     *
     * @param _minLockPeriod Minimum lock period in seconds
     */
    function setMinLockPeriod(uint64 _minLockPeriod) external;
}