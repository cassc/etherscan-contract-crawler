// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./tokenomics/EmergencyMinter.sol";
import "../interfaces/IController.sol";
import "../interfaces/tokenomics/ILpTokenStaker.sol";
import "../interfaces/vendor/IBooster.sol";

contract Controller is IController, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 internal constant _MAX_WEIGHT_UPDATE_MIN_DELAY = 32 days;
    uint256 internal constant _MIN_WEIGHT_UPDATE_MIN_DELAY = 1 days;

    EnumerableSet.AddressSet internal _pools;
    EnumerableSet.AddressSet internal _activePools;

    address public immutable emergencyMinter;
    address public immutable rootToken;

    address public override convexBooster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    address public override curveHandler;
    address public override convexHandler;
    IOracle public override priceOracle;
    ICurveRegistryCache public override curveRegistryCache;

    IInflationManager public override inflationManager;
    ILpTokenStaker public override lpTokenStaker;

    uint256 public weightUpdateMinDelay;

    mapping(address => uint256) public lastWeightUpdate;

    constructor(address rootToken_, address curveRegistryCacheAddress_) {
        rootToken = rootToken_;
        curveRegistryCache = ICurveRegistryCache(curveRegistryCacheAddress_);

        EmergencyMinter emergencyMinter_ = new EmergencyMinter(IROOTToken(rootToken_), this);
        emergencyMinter_.transferOwnership(msg.sender);
        emergencyMinter = address(emergencyMinter_);
    }

    /// @notice this function is only callable by the owner or the emergencyMinter
    /// the owner is only allowed to call this function to initialize the lpTokenStaker
    /// the emergencyMinter is allowed to call this function to update the lpTokenStaker while it is active
    /// the emergencyMinter is only active for 3 months, after which point the LP token staker will
    /// effectively be immutable
    function setLpTokenStaker(address _lpTokenStaker) external {
        address currentTokenStaker = address(lpTokenStaker);
        if (msg.sender == owner()) {
            require(currentTokenStaker == address(0), "lpTokenStaker already set");
        } else {
            // this is to allow the emergencyMinter to set the lpTokenStaker while it is active
            require(msg.sender == emergencyMinter, "only owner or emergencyMinter");
        }
        lpTokenStaker = ILpTokenStaker(_lpTokenStaker);
        for (uint256 i; i < _pools.length(); i++) {
            lpTokenStaker.checkpoint(_pools.at(i));
        }
    }

    function listPools() external view override returns (address[] memory) {
        return _pools.values();
    }

    function listActivePools() external view override returns (address[] memory) {
        return _activePools.values();
    }

    function addPool(address poolAddress) external override onlyOwner {
        require(_pools.add(poolAddress), "failed to add pool");
        require(_activePools.add(poolAddress), "failed to add pool");
        lpTokenStaker.checkpoint(poolAddress);
        emit PoolAdded(poolAddress);
    }

    function removePool(address poolAddress) external override onlyOwner {
        require(_pools.remove(poolAddress), "failed to remove pool");
        require(!_activePools.contains(poolAddress), "shutdown the pool before removing it");
        emit PoolRemoved(poolAddress);
    }

    function shutdownPool(address poolAddress) external override onlyOwner {
        require(_activePools.remove(poolAddress), "failed to remove pool");
        IRootPool(poolAddress).shutdownPool();
        inflationManager.updatePoolWeights();
        emit PoolShutdown(poolAddress);
    }

    function isPool(address poolAddress) external view override returns (bool) {
        return _pools.contains(poolAddress);
    }

    function isActivePool(address poolAddress) external view override returns (bool) {
        return _activePools.contains(poolAddress);
    }

    function updateWeights(WeightUpdate memory update) public override onlyOwner {
        require(
            lastWeightUpdate[update.rootPoolAddress] + weightUpdateMinDelay < block.timestamp,
            "weight update delay not elapsed"
        );
        IRootPool(update.rootPoolAddress).updateWeights(update.weights);
        lastWeightUpdate[update.rootPoolAddress] = block.timestamp;
    }

    function updateAllWeights(WeightUpdate[] memory weights) external override onlyOwner {
        for (uint256 i; i < weights.length; i++) {
            updateWeights(weights[i]);
        }
    }

    function setConvexBooster(address _convexBooster) external override onlyOwner {
        require(IBooster(convexBooster).isShutdown(), "current booster is not shutdown");
        convexBooster = _convexBooster;
        emit ConvexBoosterSet(_convexBooster);
    }

    function setCurveHandler(address _curveHandler) external override onlyOwner {
        curveHandler = _curveHandler;
        emit CurveHandlerSet(_curveHandler);
    }

    function setConvexHandler(address _convexHandler) external override onlyOwner {
        convexHandler = _convexHandler;
        emit ConvexHandlerSet(_convexHandler);
    }

    function setInflationManager(address manager) external onlyOwner {
        inflationManager = IInflationManager(manager);
        emit InflationManagerSet(manager);
    }

    function setPriceOracle(address oracle) external override onlyOwner {
        priceOracle = IOracle(oracle);
        emit PriceOracleSet(oracle);
    }

    function setCurveRegistryCache(address curveRegistryCache_) external override onlyOwner {
        curveRegistryCache = ICurveRegistryCache(curveRegistryCache_);
        emit CurveRegistryCacheSet(curveRegistryCache_);
    }

    function setWeightUpdateMinDelay(uint256 delay) external override onlyOwner {
        require(delay < _MAX_WEIGHT_UPDATE_MIN_DELAY, "delay too long");
        require(delay > _MIN_WEIGHT_UPDATE_MIN_DELAY, "delay too short");
        weightUpdateMinDelay = delay;
        emit WeightUpdateMinDelaySet(delay);
    }
}