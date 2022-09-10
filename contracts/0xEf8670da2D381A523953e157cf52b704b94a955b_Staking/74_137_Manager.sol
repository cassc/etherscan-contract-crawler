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
import "../interfaces/events/Destinations.sol";
import "../interfaces/events/CycleRolloverEvent.sol";
import "../interfaces/events/IEventSender.sol";

//solhint-disable not-rely-on-time 
//solhint-disable var-name-mixedcase
contract Manager is IManager, Initializable, AccessControl, IEventSender {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes32 public immutable ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public immutable ROLLOVER_ROLE = keccak256("ROLLOVER_ROLE");
    bytes32 public immutable MID_CYCLE_ROLE = keccak256("MID_CYCLE_ROLE");
    bytes32 public immutable START_ROLLOVER_ROLE = keccak256("START_ROLLOVER_ROLE");
    bytes32 public immutable ADD_LIQUIDITY_ROLE = keccak256("ADD_LIQUIDITY_ROLE");
    bytes32 public immutable REMOVE_LIQUIDITY_ROLE = keccak256("REMOVE_LIQUIDITY_ROLE");
    bytes32 public immutable MISC_OPERATION_ROLE = keccak256("MISC_OPERATION_ROLE");

    uint256 public currentCycle; // Start timestamp of current cycle
    uint256 public currentCycleIndex; // Uint representing current cycle
    uint256 public cycleDuration; // Cycle duration in seconds

    bool public rolloverStarted;

    // Bytes32 controller id => controller address
    mapping(bytes32 => address) public registeredControllers;
    // Cycle index => ipfs rewards hash
    mapping(uint256 => string) public override cycleRewardsHashes;
    EnumerableSet.AddressSet private pools;
    EnumerableSet.Bytes32Set private controllerIds;

    // Reentrancy Guard
    bool private _entered;

    bool public _eventSend;
    Destinations public destinations;

    uint256 public nextCycleStartTime;

    bool private isLogicContract;

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

    modifier nonReentrant() {
        require(!_entered, "ReentrancyGuard: reentrant call");
        _entered = true;
        _;
        _entered = false;
    }

    modifier onEventSend() {
        if (_eventSend) {
            _;
        }
    }

    modifier onlyStartRollover() {
        require(hasRole(START_ROLLOVER_ROLE, _msgSender()), "NOT_START_ROLLOVER_ROLE");
        _;
    }

    constructor() public {
        isLogicContract = true;
    }

    function initialize(uint256 _cycleDuration, uint256 _nextCycleStartTime) public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();

        cycleDuration = _cycleDuration;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(ROLLOVER_ROLE, _msgSender());
        _setupRole(MID_CYCLE_ROLE, _msgSender());
        _setupRole(START_ROLLOVER_ROLE, _msgSender());
        _setupRole(ADD_LIQUIDITY_ROLE, _msgSender());
        _setupRole(REMOVE_LIQUIDITY_ROLE, _msgSender());
        _setupRole(MISC_OPERATION_ROLE, _msgSender());

        setNextCycleStartTime(_nextCycleStartTime);
    }

    function registerController(bytes32 id, address controller) external override onlyAdmin {
        registeredControllers[id] = controller;
        require(controllerIds.add(id), "ADD_FAIL");
        emit ControllerRegistered(id, controller);
    }

    function unRegisterController(bytes32 id) external override onlyAdmin {
        emit ControllerUnregistered(id, registeredControllers[id]);
        delete registeredControllers[id];
        require(controllerIds.remove(id), "REMOVE_FAIL");
    }

    function registerPool(address pool) external override onlyAdmin {
        require(pools.add(pool), "ADD_FAIL");
        emit PoolRegistered(pool);
    }

    function unRegisterPool(address pool) external override onlyAdmin {
        require(pools.remove(pool), "REMOVE_FAIL");
        emit PoolUnregistered(pool);
    }

    function setCycleDuration(uint256 duration) external override onlyAdmin {
        require(duration > 60, "CYCLE_TOO_SHORT");
        cycleDuration = duration;
        emit CycleDurationSet(duration);
    }

    function setNextCycleStartTime(uint256 _nextCycleStartTime) public override onlyAdmin {
        // We are aware of the possibility of timestamp manipulation.  It does not pose any
        // risk based on the design of our system
        require(_nextCycleStartTime > block.timestamp, "MUST_BE_FUTURE");
        nextCycleStartTime = _nextCycleStartTime;
        emit NextCycleStartSet(_nextCycleStartTime);
    }

    function getPools() external view override returns (address[] memory) {
        uint256 poolsLength = pools.length();
        address[] memory returnData = new address[](poolsLength);
        for (uint256 i = 0; i < poolsLength; ++i) {
            returnData[i] = pools.at(i);
        }
        return returnData;
    }

    function getControllers() external view override returns (bytes32[] memory) {
        uint256 controllerIdsLength = controllerIds.length();
        bytes32[] memory returnData = new bytes32[](controllerIdsLength);
        for (uint256 i = 0; i < controllerIdsLength; ++i) {
            returnData[i] = controllerIds.at(i);
        }
        return returnData;
    }

    function completeRollover(string calldata rewardsIpfsHash) external override onlyRollover {
        // Can't be hit via test cases, going to leave in anyways in case we ever change code
        require(nextCycleStartTime > 0, "SET_BEFORE_ROLLOVER");
        // We are aware of the possibility of timestamp manipulation.  It does not pose any
        // risk based on the design of our system
        require(block.timestamp > nextCycleStartTime, "PREMATURE_EXECUTION");
        _completeRollover(rewardsIpfsHash);
    }

    /// @notice Used for mid-cycle adjustments
    function executeMaintenance(MaintenanceExecution calldata params)
        external
        override
        onlyMidCycle
        nonReentrant
    {
        for (uint256 x = 0; x < params.cycleSteps.length; ++x) {
            _executeControllerCommand(params.cycleSteps[x]);
        }
    }

    function executeRollover(RolloverExecution calldata params) external override onlyRollover nonReentrant {
        // We are aware of the possibility of timestamp manipulation.  It does not pose any
        // risk based on the design of our system
        require(block.timestamp > nextCycleStartTime, "PREMATURE_EXECUTION");

        // Transfer deployable liquidity out of the pools and into the manager
        for (uint256 i = 0; i < params.poolData.length; ++i) {
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
        for (uint256 x = 0; x < params.cycleSteps.length; ++x) {
            _executeControllerCommand(params.cycleSteps[x]);
        }

        // Transfer recovered liquidity back into the pools; leave no funds in the manager
        for (uint256 y = 0; y < params.poolsForWithdraw.length; ++y) {
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

    function sweep(address[] calldata poolAddresses) external override onlyRollover {

        uint256 length = poolAddresses.length;
        uint256[] memory amounts = new uint256[](length);

        for (uint256 i = 0; i < length; ++i) {
            address currentPoolAddress = poolAddresses[i];
            require(pools.contains(currentPoolAddress), "INVALID_ADDRESS");
            IERC20 underlyer = IERC20(ILiquidityPool(currentPoolAddress).underlyer());
            uint256 amount = underlyer.balanceOf(address(this));
            amounts[i] = amount;
            
            if (amount > 0) {
                underlyer.safeTransfer(currentPoolAddress, amount);
            }
        }
        emit ManagerSwept(poolAddresses, amounts);
    }

    function _executeControllerCommand(ControllerTransferData calldata transfer) private {
        require(!isLogicContract, "FORBIDDEN_CALL");

        address controllerAddress = registeredControllers[transfer.controllerId];
        require(controllerAddress != address(0), "INVALID_CONTROLLER");
        controllerAddress.functionDelegateCall(transfer.data, "CYCLE_STEP_EXECUTE_FAILED");
        emit DeploymentStepExecuted(transfer.controllerId, controllerAddress, transfer.data);
    }

    function startCycleRollover() external override onlyStartRollover {
        // We are aware of the possibility of timestamp manipulation.  It does not pose any
        // risk based on the design of our system
        require(block.timestamp > nextCycleStartTime, "PREMATURE_EXECUTION");
        rolloverStarted = true;

        bytes32 eventSig = "Cycle Rollover Start";
        encodeAndSendData(eventSig);

        emit CycleRolloverStarted(block.timestamp);
    }

    function _completeRollover(string calldata rewardsIpfsHash) private {
        currentCycle = nextCycleStartTime;
        nextCycleStartTime = nextCycleStartTime.add(cycleDuration);
        cycleRewardsHashes[currentCycleIndex] = rewardsIpfsHash;
        currentCycleIndex = currentCycleIndex.add(1);
        rolloverStarted = false;

        bytes32 eventSig = "Cycle Complete";
        encodeAndSendData(eventSig);

        emit CycleRolloverComplete(block.timestamp);
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

    function setDestinations(address _fxStateSender, address _destinationOnL2) external override onlyAdmin {
        require(_fxStateSender != address(0), "INVALID_ADDRESS");
        require(_destinationOnL2 != address(0), "INVALID_ADDRESS");

        destinations.fxStateSender = IFxStateSender(_fxStateSender);
        destinations.destinationOnL2 = _destinationOnL2;

        emit DestinationsSet(_fxStateSender, _destinationOnL2);
    }

    function setEventSend(bool _eventSendSet) external override onlyAdmin {
        require(destinations.destinationOnL2 != address(0), "DESTINATIONS_NOT_SET");
        
        _eventSend = _eventSendSet;

        emit EventSendSet(_eventSendSet);
    }

    function setupRole(bytes32 role) external override onlyAdmin {
        _setupRole(role, _msgSender());
    }

    function encodeAndSendData(bytes32 _eventSig) private onEventSend {
        require(address(destinations.fxStateSender) != address(0), "ADDRESS_NOT_SET");
        require(destinations.destinationOnL2 != address(0), "ADDRESS_NOT_SET");

        bytes memory data = abi.encode(CycleRolloverEvent({
            eventSig: _eventSig,
            cycleIndex: currentCycleIndex,
            timestamp: currentCycle
        }));

        destinations.fxStateSender.sendMessageToChild(destinations.destinationOnL2, data);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}