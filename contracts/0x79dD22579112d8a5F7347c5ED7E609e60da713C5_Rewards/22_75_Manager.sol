// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/IManager.sol";
import "../interfaces/ILiquidityPool.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import {EnumerableSetUpgradeable as EnumerableSet} from "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import {SafeMathUpgradeable as SafeMath} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {AccessControlUpgradeable as AccessControl} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract Manager is IManager, Initializable, AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ROLLOVER_ROLE = keccak256("ROLLOVER_ROLE");
    bytes32 public constant MID_CYCLE_ROLE = keccak256("MID_CYCLE_ROLE");

    uint256 public currentCycle;
    uint256 public currentCycleIndex;
    uint256 public cycleDuration;

    bool public rolloverStarted;

    mapping(bytes32 => address) public registeredControllers;
    mapping(uint256 => string) public override cycleRewardsHashes;
    EnumerableSet.AddressSet private pools;
    EnumerableSet.Bytes32Set private controllerIds;

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NOT_ADMIN_ROLE");
        _;
    }

    modifier onlyRollover() {
        require(hasRole(ROLLOVER_ROLE, _msgSender()), "NOT_ROLLOVER_ROLE");
        _;
    }

    modifier onlyMidCycle() {
        require(hasRole(MID_CYCLE_ROLE, _msgSender()), "NOT_MID_CYCLE_ROLE");
        _;
    }

    function initialize(uint256 _cycleDuration) public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();

        cycleDuration = _cycleDuration;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(ROLLOVER_ROLE, _msgSender());
        _setupRole(MID_CYCLE_ROLE, _msgSender());
    }

    function registerController(bytes32 id, address controller) external override onlyAdmin {
        require(!controllerIds.contains(id), "CONTROLLER_EXISTS");
        registeredControllers[id] = controller;
        controllerIds.add(id);
        emit ControllerRegistered(id, controller);
    }

    function unRegisterController(bytes32 id) external override onlyAdmin {
        require(controllerIds.contains(id), "INVALID_CONTROLLER");
        emit ControllerUnregistered(id, registeredControllers[id]);
        delete registeredControllers[id];
        controllerIds.remove(id);
    }

    function registerPool(address pool) external override onlyAdmin {
        require(!pools.contains(pool), "POOL_EXISTS");
        pools.add(pool);
        emit PoolRegistered(pool);
    }

    function unRegisterPool(address pool) external override onlyAdmin {
        require(pools.contains(pool), "INVALID_POOL");
        pools.remove(pool);
        emit PoolUnregistered(pool);
    }

    function setCycleDuration(uint256 duration) external override onlyAdmin {
        cycleDuration = duration;
        emit CycleDurationSet(duration);
    }

    function getPools() external view override returns (address[] memory) {
        address[] memory returnData = new address[](pools.length());
        for (uint256 i = 0; i < pools.length(); i++) {
            returnData[i] = pools.at(i);
        }
        return returnData;
    }

    function getControllers() external view override returns (bytes32[] memory) {
        bytes32[] memory returnData = new bytes32[](controllerIds.length());
        for (uint256 i = 0; i < controllerIds.length(); i++) {
            returnData[i] = controllerIds.at(i);
        }
        return returnData;
    }

    function completeRollover(string calldata rewardsIpfsHash) external override onlyRollover {
        require(block.number > (currentCycle.add(cycleDuration)), "PREMATURE_EXECUTION");
        _completeRollover(rewardsIpfsHash);
    }

    function executeMaintenance(MaintenanceExecution calldata params)
        external
        override
        onlyMidCycle
    {
        for (uint256 x = 0; x < params.cycleSteps.length; x++) {
            _executeControllerCommand(params.cycleSteps[x]);
        }
    }

    function executeRollover(RolloverExecution calldata params) external override onlyRollover {
        require(block.number > (currentCycle.add(cycleDuration)), "PREMATURE_EXECUTION");

        // Transfer deployable liquidity out of the pools and into the manager
        for (uint256 i = 0; i < params.poolData.length; i++) {
            require(pools.contains(params.poolData[i].pool), "INVALID_POOL");
            ILiquidityPool pool = ILiquidityPool(params.poolData[i].pool);
            IERC20 underlyingToken = pool.underlyer();
            underlyingToken.safeTransferFrom(
                address(pool),
                address(this),
                params.poolData[i].amount
            );
            emit LiquidityMovedToManager(params.poolData[i].pool, params.poolData[i].amount);
        }

        // Deploy or withdraw liquidity
        for (uint256 x = 0; x < params.cycleSteps.length; x++) {
            _executeControllerCommand(params.cycleSteps[x]);
        }

        // Transfer recovered liquidity back into the pools; leave no funds in the manager
        for (uint256 y = 0; y < params.poolsForWithdraw.length; y++) {
            require(pools.contains(params.poolsForWithdraw[y]), "INVALID_POOL");
            ILiquidityPool pool = ILiquidityPool(params.poolsForWithdraw[y]);
            IERC20 underlyingToken = pool.underlyer();

            uint256 managerBalance = underlyingToken.balanceOf(address(this));

            // transfer funds back to the pool if there are funds
            if (managerBalance > 0) {
                underlyingToken.safeTransfer(address(pool), managerBalance);
            }
            emit LiquidityMovedToPool(params.poolsForWithdraw[y], managerBalance);
        }

        if (params.complete) {
            _completeRollover(params.rewardsIpfsHash);
        }
    }

    function _executeControllerCommand(ControllerTransferData calldata transfer) private {
        address controllerAddress = registeredControllers[transfer.controllerId];
        require(controllerAddress != address(0), "INVALID_CONTROLLER");
        controllerAddress.functionDelegateCall(transfer.data, "CYCLE_STEP_EXECUTE_FAILED");
        emit DeploymentStepExecuted(transfer.controllerId, controllerAddress, transfer.data);
    }

    function startCycleRollover() external override onlyRollover {
        rolloverStarted = true;
        emit CycleRolloverStarted(block.number);
    }

    function _completeRollover(string calldata rewardsIpfsHash) private {
        currentCycle = block.number;
        cycleRewardsHashes[currentCycleIndex] = rewardsIpfsHash;
        currentCycleIndex = currentCycleIndex.add(1);
        rolloverStarted = false;
        emit CycleRolloverComplete(block.number);
    }

    function getCurrentCycle() external view override returns (uint256) {
        return currentCycle;
    }

    function getCycleDuration() external view override returns (uint256) {
        return cycleDuration;
    }

    function getCurrentCycleIndex() external view override returns (uint256) {
        return currentCycleIndex;
    }

    function getRolloverStatus() external view override returns (bool) {
        return rolloverStarted;
    }
}