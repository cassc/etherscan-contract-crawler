// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "Ownable.sol";
import "EnumerableSet.sol";

import "IRebalancingRewardsHandler.sol";
import "IInflationManager.sol";
import "IController.sol";
import "ICNCToken.sol";
import "IConicPool.sol";
import "ILpToken.sol";

import "ScaledMath.sol";

contract InflationManager is IInflationManager, Ownable {
    using ScaledMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    ICNCToken public constant CNC = ICNCToken(0x9aE380F0272E2162340a5bB646c354271c0F5cFC);

    IController public immutable controller;

    uint256 internal constant _INITIAL_INFLATION_RATE = 1_500_000 * 1e18;
    uint256 internal constant _INFLATION_RATE_DECAY = 0.3999999 * 1e18;
    uint256 internal constant _INFLATION_RATE_PERIOD = 365 days;

    /// @dev mapping from conic pool to their rebalancing reward handlers
    mapping(address => EnumerableSet.AddressSet) internal _rebalancingRewardHandlers;

    uint256 public override currentInflationRate;
    uint256 public lastInflationRateDecay;
    uint256 public lastUpdate;
    uint256 public totalLpInflationMinted;

    mapping(address => uint256) public currentPoolWeights;

    constructor(address _controller) Ownable() {
        require(_controller != address(0), "Cannot use zero address for controller");
        controller = IController(_controller);

        currentInflationRate = _INITIAL_INFLATION_RATE / _INFLATION_RATE_PERIOD;
        lastUpdate = block.timestamp;
        lastInflationRateDecay = block.timestamp;
    }

    /// @notice returns the weights of the Conic pools to know how much inflation
    /// each of them will receive. totalUSDValue only accounts for funds in active pools
    function computePoolWeights()
        public
        view
        override
        returns (
            address[] memory pools,
            uint256[] memory poolWeights,
            uint256 totalUSDValue
        )
    {
        IOracle oracle = controller.priceOracle();
        pools = controller.listPools();
        uint256[] memory poolUSDValues = new uint256[](pools.length);
        for (uint256 i; i < pools.length; i++) {
            if (controller.isActivePool(pools[i])) {
                IConicPool pool = IConicPool(pools[i]);
                IERC20Metadata underlying = pool.underlying();
                uint256 price = oracle.getUSDPrice(address(underlying));
                uint256 poolUSDValue = pool
                    .cachedTotalUnderlying()
                    .convertScale(underlying.decimals(), 18)
                    .mulDown(price);
                poolUSDValues[i] = poolUSDValue;
                totalUSDValue += poolUSDValue;
            }
        }

        poolWeights = new uint256[](pools.length);

        if (totalUSDValue == 0) {
            for (uint256 i; i < pools.length; i++) {
                poolWeights[i] = ScaledMath.ONE / pools.length;
            }
        } else {
            for (uint256 i; i < pools.length; i++) {
                poolWeights[i] = poolUSDValues[i].divDown(totalUSDValue);
            }
        }
    }

    /// @notice Same as `computePoolWeights` but only returns the value for a single pool
    /// totalUSDValue only accounts for funds in active pools
    function computePoolWeight(address pool)
        public
        view
        returns (uint256 poolWeight, uint256 totalUSDValue)
    {
        require(controller.isPool(pool), "pool not found");
        IOracle oracle = controller.priceOracle();
        address[] memory pools = controller.listPools();
        uint256 poolUSDValue;
        for (uint256 i; i < pools.length; i++) {
            if (controller.isActivePool(pools[i])) {
                IConicPool currentPool = IConicPool(pools[i]);
                IERC20Metadata underlying = currentPool.underlying();
                uint256 price = oracle.getUSDPrice(address(underlying));
                uint256 usdValue = currentPool
                    .cachedTotalUnderlying()
                    .convertScale(underlying.decimals(), 18)
                    .mulDown(price);
                totalUSDValue += usdValue;
                if (address(currentPool) == pool) poolUSDValue = usdValue;
            }
        }

        if (!controller.isActivePool(pool)) {
            return (0, totalUSDValue);
        }
        poolWeight = totalUSDValue == 0
            ? ScaledMath.ONE / pools.length
            : poolUSDValue.divDown(totalUSDValue);
    }

    function executeInflationRateUpdate() external override {
        _executeInflationRateUpdate();
    }

    function handleRebalancingRewards(
        address account,
        uint256 deviationBefore,
        uint256 deviationAfter
    ) external {
        require(controller.isPool(msg.sender), "only pools can call this function");
        for (uint256 i; i < _rebalancingRewardHandlers[msg.sender].length(); i++) {
            address handler = _rebalancingRewardHandlers[msg.sender].at(i);
            IRebalancingRewardsHandler(handler).handleRebalancingRewards(
                IConicPool(msg.sender),
                account,
                deviationBefore,
                deviationAfter
            );
        }
    }

    function addPoolRebalancingRewardHandler(address poolAddress, address rebalancingRewardHandler)
        external
        override
    {
        require(
            msg.sender == owner() || msg.sender == controller.emergencyMinter(),
            "only owner or emergency minter"
        );
        require(controller.isPool(poolAddress), "invalid pool");
        require(
            _rebalancingRewardHandlers[poolAddress].add(rebalancingRewardHandler),
            "handler already set"
        );

        emit RebalancingRewardHandlerAdded(poolAddress, rebalancingRewardHandler);
    }

    function removePoolRebalancingRewardHandler(
        address poolAddress,
        address rebalancingRewardHandler
    ) external override {
        require(
            msg.sender == owner() || msg.sender == controller.emergencyMinter(),
            "only owner or emergency minter"
        );
        require(controller.isPool(poolAddress), "invalid pool");
        require(
            _rebalancingRewardHandlers[poolAddress].remove(rebalancingRewardHandler),
            "handler not set"
        );
        emit RebalancingRewardHandlerRemoved(poolAddress, rebalancingRewardHandler);
    }

    function hasPoolRebalancingRewardHandlers(address poolAddress, address handler)
        external
        view
        returns (bool)
    {
        return _rebalancingRewardHandlers[poolAddress].contains(handler);
    }

    function rebalancingRewardHandlers(address poolAddress)
        external
        view
        returns (address[] memory)
    {
        return _rebalancingRewardHandlers[poolAddress].values();
    }

    function updatePoolWeights() public override {
        (address[] memory _pools, uint256[] memory poolWeights, ) = computePoolWeights();
        uint256 numPools = _pools.length;
        ILpTokenStaker lpTokenStaker = controller.lpTokenStaker();
        for (uint256 i; i < numPools; i++) {
            address curPool = _pools[i];
            IRewardManager(IConicPool(curPool).rewardManager()).poolCheckpoint();
            lpTokenStaker.checkpoint(curPool);
            currentPoolWeights[curPool] = poolWeights[i];
        }
        emit PoolWeightsUpdated();
    }

    /// @dev Pool weights will be updated periodically
    function getCurrentPoolInflationRate(address pool) external view override returns (uint256) {
        return currentInflationRate.mulDown(currentPoolWeights[pool]);
    }

    function _executeInflationRateUpdate() internal {
        if (block.timestamp >= lastInflationRateDecay + _INFLATION_RATE_PERIOD) {
            updatePoolWeights();
            currentInflationRate = currentInflationRate.mulDown(_INFLATION_RATE_DECAY);
            lastInflationRateDecay = block.timestamp;
        }
    }
}