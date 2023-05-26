// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "Ownable.sol";

import "Initializable.sol";
import "EnumerableSet.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "SafeERC20.sol";

import "ICNCMintingRebalancingRewardsHandlerV2.sol";
import "ICNCMintingRebalancingRewardsHandler.sol";
import "IInflationManager.sol";
import "ICNCToken.sol";
import "IConicPool.sol";
import "ScaledMath.sol";
import "BaseMinter.sol";

contract CNCMintingRebalancingRewardsHandlerV2 is
    ICNCMintingRebalancingRewardsHandlerV2,
    Ownable,
    BaseMinter,
    Initializable
{
    using SafeERC20 for IERC20;
    using ScaledMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev the maximum amount of CNC that can be minted for rebalancing rewards
    uint256 internal constant _MAX_REBALANCING_REWARDS = 1_900_000e18; // 19% of total supply

    /// @dev gives out 5 dollars per 1 hour (assuming 1 CNC = 6 USD) for every 10,000 USD in TVL that needs to be shifted
    uint256 internal constant _INITIAL_REBALANCING_REWARD_PER_DOLLAR_PER_SECOND =
        5e18 / uint256(3600 * 1 * 10_000 * 6);

    IController public immutable override controller;

    ICNCMintingRebalancingRewardsHandler public immutable previousRewardsHandler;
    uint256 public override totalCncMinted;
    uint256 public override cncRebalancingRewardPerDollarPerSecond;

    bool internal _isInternal;

    modifier onlyInflationManager() {
        require(
            msg.sender == address(controller.inflationManager()),
            "only InflationManager can call this function"
        );
        _;
    }

    /// NOTE: we do not use the `emergencyMinter` anymore so we pass in address(0) as the emergency minter
    /// to disable the usage of `renounceMinterRights`
    /// From V3, we can remove the dependency on `BaseMinter` altogether but for now we need it
    /// to be able to call `EmergencyMinter.switchRebalancingRewardsHandler`
    constructor(
        IController _controller,
        ICNCToken _cnc,
        ICNCMintingRebalancingRewardsHandler _previousRewardsHandler
    ) BaseMinter(_cnc, address(0)) {
        cncRebalancingRewardPerDollarPerSecond = _INITIAL_REBALANCING_REWARD_PER_DOLLAR_PER_SECOND;
        controller = _controller;
        previousRewardsHandler = _previousRewardsHandler;
    }

    function initialize() external onlyOwner initializer {
        totalCncMinted = previousRewardsHandler.totalCncMinted();
    }

    function setCncRebalancingRewardPerDollarPerSecond(
        uint256 _cncRebalancingRewardPerDollarPerSecond
    ) external override onlyOwner {
        cncRebalancingRewardPerDollarPerSecond = _cncRebalancingRewardPerDollarPerSecond;
        emit SetCncRebalancingRewardPerDollarPerSecond(_cncRebalancingRewardPerDollarPerSecond);
    }

    function _distributeRebalancingRewards(address pool, address account, uint256 amount) internal {
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

    function handleRebalancingRewards(
        IConicPool conicPool,
        address account,
        uint256 deviationBefore,
        uint256 deviationAfter
    ) external onlyInflationManager {
        _handleRebalancingRewards(conicPool, account, deviationBefore, deviationAfter);
    }

    function _handleRebalancingRewards(
        IConicPool conicPool,
        address account,
        uint256 deviationBefore,
        uint256 deviationAfter
    ) internal {
        if (_isInternal) return;
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
        uint256 deviationDelta = deviationBefore - deviationAfter;
        uint256 lastWeightUpdate = controller.lastWeightUpdate(conicPool);
        uint256 elapsedSinceUpdate = uint256(block.timestamp) - lastWeightUpdate;
        return
            (elapsedSinceUpdate * cncRebalancingRewardPerDollarPerSecond).mulDown(deviationDelta);
    }

    function rebalance(
        address conicPool,
        uint256 underlyingAmount,
        uint256 minUnderlyingReceived,
        uint256 minCNCReceived
    ) external override returns (uint256 underlyingReceived, uint256 cncReceived) {
        require(controller.isPool(conicPool), "not a pool");
        IConicPool conicPool_ = IConicPool(conicPool);
        IERC20 underlying = conicPool_.underlying();
        require(underlying.balanceOf(msg.sender) >= underlyingAmount, "insufficient underlying");
        uint256 deviationBefore = conicPool_.computeTotalDeviation();
        underlying.safeTransferFrom(msg.sender, address(this), underlyingAmount);
        underlying.safeApprove(conicPool, underlyingAmount);
        _isInternal = true;
        uint256 lpTokenAmount = conicPool_.deposit(underlyingAmount, 0, false);
        _isInternal = false;
        underlyingReceived = conicPool_.withdraw(lpTokenAmount, 0);
        require(underlyingReceived >= minUnderlyingReceived, "insufficient underlying received");
        uint256 deviationAfter = conicPool_.computeTotalDeviation();
        uint256 cncBefore = cnc.balanceOf(msg.sender);
        _handleRebalancingRewards(conicPool_, msg.sender, deviationBefore, deviationAfter);
        cncReceived = cnc.balanceOf(msg.sender) - cncBefore;
        require(cncReceived >= minCNCReceived, "insufficient CNC received");
        underlying.safeTransfer(msg.sender, underlyingReceived);
    }

    /// @notice switches the minting rebalancing reward handler by granting the new one minting rights
    /// and renouncing his own
    /// `InflationManager.removePoolRebalancingRewardHandler` should be called on every pool before this is called
    /// this should typically be done as a single batched governance action
    /// The same governance action should also call `InflationManager.addPoolRebalancingRewardHandler` for each pool
    /// passing in `newRebalancingRewardsHandler` so that the whole operation is atomic
    /// @param newRebalancingRewardsHandler the address of the new rebalancing rewards handler
    function switchMintingRebalancingRewardsHandler(
        address newRebalancingRewardsHandler
    ) external onlyOwner {
        address[] memory pools = controller.listPools();
        for (uint256 i; i < pools.length; i++) {
            require(
                !controller.inflationManager().hasPoolRebalancingRewardHandlers(
                    pools[i],
                    address(this)
                ),
                "handler is still registered for a pool"
            );
        }
        cnc.addMinter(newRebalancingRewardsHandler);
        cnc.renounceMinterRights();
    }
}