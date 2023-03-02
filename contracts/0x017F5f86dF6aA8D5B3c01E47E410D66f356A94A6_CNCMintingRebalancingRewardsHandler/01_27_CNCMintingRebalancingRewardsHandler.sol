// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "Ownable.sol";

import "EnumerableSet.sol";

import "ICNCMintingRebalancingRewardsHandler.sol";
import "IInflationManager.sol";
import "ICNCToken.sol";
import "IConicPool.sol";
import "ScaledMath.sol";
import "BaseMinter.sol";

contract CNCMintingRebalancingRewardsHandler is
    ICNCMintingRebalancingRewardsHandler,
    Ownable,
    BaseMinter
{
    using ScaledMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev the maximum amount of CNC that can be minted for rebalancing rewards
    uint256 internal constant _MAX_REBALANCING_REWARDS = 1_900_000e18; // 19% of total supply

    /// @dev gives out 1 dollar per 1 hour (assuming 1 CNC = 10 USD) for every 10,000 USD of TVL
    uint256 internal constant _INITIAL_REBALANCING_REWARD_PER_DOLLAR_PER_SECOND =
        1e18 / uint256(3600 * 1 * 10_000 * 10);

    /// @dev to avoid CNC rewards being too low, the TVL is assumed to be at least 10k
    /// when computing the rebalancing rewards
    uint256 internal constant _INITIAL_MIN_REBALANCING_REWARD_DOLLAR_MULTIPLIER = 10_000e18;

    /// @dev to avoid CNC rewards being too high, the TVL is assumed to be at most 10m
    /// when computing the rebalancing rewards
    uint256 internal constant _INITIAL_MAX_REBALANCING_REWARD_DOLLAR_MULTIPLIER = 10_000_000e18;

    IController public immutable override controller;

    uint256 public override totalCncMinted;
    uint256 public override cncRebalancingRewardPerDollarPerSecond;
    uint256 public override maxRebalancingRewardDollarMultiplier;
    uint256 public override minRebalancingRewardDollarMultiplier;

    modifier onlyInflationManager() {
        require(
            msg.sender == address(controller.inflationManager()),
            "only InflationManager can call this function"
        );
        _;
    }

    constructor(
        IController _controller,
        ICNCToken _cnc,
        address emergencyMinter
    ) BaseMinter(_cnc, emergencyMinter) {
        cncRebalancingRewardPerDollarPerSecond = _INITIAL_REBALANCING_REWARD_PER_DOLLAR_PER_SECOND;
        minRebalancingRewardDollarMultiplier = _INITIAL_MIN_REBALANCING_REWARD_DOLLAR_MULTIPLIER;
        maxRebalancingRewardDollarMultiplier = _INITIAL_MAX_REBALANCING_REWARD_DOLLAR_MULTIPLIER;
        controller = _controller;
    }

    function setCncRebalancingRewardPerDollarPerSecond(
        uint256 _cncRebalancingRewardPerDollarPerSecond
    ) external override onlyOwner {
        cncRebalancingRewardPerDollarPerSecond = _cncRebalancingRewardPerDollarPerSecond;
        emit SetCncRebalancingRewardPerDollarPerSecond(_cncRebalancingRewardPerDollarPerSecond);
    }

    function setMaxRebalancingRewardDollarMultiplier(uint256 _maxRebalancingRewardDollarMultiplier)
        external
        override
        onlyOwner
    {
        maxRebalancingRewardDollarMultiplier = _maxRebalancingRewardDollarMultiplier;
        emit SetMaxRebalancingRewardDollarMultiplier(_maxRebalancingRewardDollarMultiplier);
    }

    function setMinRebalancingRewardDollarMultiplier(uint256 _minRebalancingRewardDollarMultiplier)
        external
        override
        onlyOwner
    {
        minRebalancingRewardDollarMultiplier = _minRebalancingRewardDollarMultiplier;
        emit SetMinRebalancingRewardDollarMultiplier(_minRebalancingRewardDollarMultiplier);
    }

    function _distributeRebalancingRewards(
        address pool,
        address account,
        uint256 amount
    ) internal {
        if (totalCncMinted + amount > _MAX_REBALANCING_REWARDS) {
            amount = _MAX_REBALANCING_REWARDS - totalCncMinted;
        }
        if (amount == 0) return;
        uint256 mintedAmount = cnc.mint(account, amount);
        if (mintedAmount > 0) {
            totalCncMinted += mintedAmount;
            emit RebalancingRewardDistributed(pool, account, address(cnc), mintedAmount);
        }
    }

    function poolCNCRebalancingRewardPerSecond(address pool)
        public
        view
        override
        returns (uint256)
    {
        (uint256 poolWeight, uint256 totalUSDValue) = controller
            .inflationManager()
            .computePoolWeight(pool);
        uint256 tvlMultiplier = totalUSDValue;
        if (tvlMultiplier < minRebalancingRewardDollarMultiplier)
            tvlMultiplier = minRebalancingRewardDollarMultiplier;
        if (tvlMultiplier > maxRebalancingRewardDollarMultiplier)
            tvlMultiplier = maxRebalancingRewardDollarMultiplier;
        return cncRebalancingRewardPerDollarPerSecond.mulDown(poolWeight).mulDown(tvlMultiplier);
    }

    function handleRebalancingRewards(
        IConicPool conicPool,
        address account,
        uint256 deviationBefore,
        uint256 deviationAfter
    ) external onlyInflationManager {
        uint256 cncRewardAmount = computeRebalancingRewards(
            address(conicPool),
            deviationBefore,
            deviationAfter
        );
        _distributeRebalancingRewards(address(conicPool), account, cncRewardAmount);
    }

    /// @dev this computes how much CNC a user should get when depositing
    /// this does not check whether the rewards should still be distributed
    /// amount CNC = t * CNC/s * (1 - (Δdeviation / initialDeviation))
    /// where
    /// CNC/s: the amount of CNC per second to distributed for rebalancing
    /// t: the time elapsed since the weight update
    /// Δdeviation: the deviation difference caused by this deposit
    /// initialDeviation: the deviation after updating weights
    /// @return the amount of CNC to give to the user as reward
    function computeRebalancingRewards(
        address conicPool,
        uint256 deviationBefore,
        uint256 deviationAfter
    ) public view override returns (uint256) {
        if (deviationBefore < deviationAfter) return 0;
        uint256 cncPerSecond = poolCNCRebalancingRewardPerSecond(conicPool);
        uint256 deviationDelta = deviationBefore - deviationAfter;
        uint256 deviationImprovementRatio = deviationDelta.divDown(
            IConicPool(conicPool).totalDeviationAfterWeightUpdate()
        );
        uint256 lastWeightUpdate = controller.lastWeightUpdate(conicPool);
        uint256 elapsedSinceUpdate = uint256(block.timestamp) - lastWeightUpdate;
        return (elapsedSinceUpdate * cncPerSecond).mulDown(deviationImprovementRatio);
    }
}