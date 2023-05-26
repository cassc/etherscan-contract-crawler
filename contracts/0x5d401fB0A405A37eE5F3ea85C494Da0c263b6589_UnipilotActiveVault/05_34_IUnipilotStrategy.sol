// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IUnipilotStrategy {
    struct PoolStrategy {
        int24 baseThreshold;
        int24 rangeThreshold;
        int24 maxTwapDeviation;
        int24 readjustThreshold;
        uint32 twapDuration;
        int24 baseMultiplier;
    }

    event GovernanceUpdated(address oldGovernance, address newGovernance);
    event StrategyUpdated(PoolStrategy oldStrategy, PoolStrategy newStrategy);
    event MaxTwapDeviationUpdated(int24 oldDeviation, int24 newDeviation);
    event BaseTicksUpdated(int24 oldBaseTicks, int24 newBaseTicks);
    event RangeTicksUpdated(int24 oldRangeTicks, int24 newRangeTicks);
    event TwapDurationUpdated(uint32 oldDuration, uint32 newDuration);
    event ReadjustMultiplierUpdated(int24 oldMultiplier, int24 newMultiplier);

    function getTicks(address _pool)
        external
        returns (
            int24 baseLower,
            int24 baseUpper,
            int24 bidLower,
            int24 bidUpper,
            int24 askLower,
            int24 askUpper
        );

    function getTwap(address _pool) external view returns (int24);

    function getStrategy(address _pool)
        external
        view
        returns (PoolStrategy memory strategy);

    function getBaseThreshold(address _pool)
        external
        view
        returns (int24 baseThreshold);

    function twapDuration() external view returns (uint32);

    function maxTwapDeviation() external view returns (int24);

    function checkDeviation(address pool) external view;
}