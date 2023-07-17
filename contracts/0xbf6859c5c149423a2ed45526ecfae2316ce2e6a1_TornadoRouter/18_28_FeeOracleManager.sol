// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// OZ Imports

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/Initializable.sol";

// Tornado Imports

import { ITornadoInstance } from "tornado-anonymity-mining/contracts/interfaces/ITornadoInstance.sol";

// Local Imports

import { IFeeOracle, FeeData, FeeDataForOracle, InstanceWithFee } from "./interfaces/IFeeOracle.sol";

import { InstanceRegistry } from "./InstanceRegistry.sol";

/**
 * @title FeeManagerLegacyStorage
 * @author AlienTornadosaurusHex
 * @dev This is contract will help us layout storage properly for a proxy upgrade for the impl
 * FeeOracleManager (formerly FeeManager).
 */
contract FeeManagerLegacyStorage {
    /**
     * @dev From first contract
     */
    uint24 private _deprecatedUniswapTornPoolSwappingFee;

    /**
     * @dev From first contract
     */
    uint32 private _deprecatedUniswapTimePeriod;

    /**
     * @dev From first contract
     */
    uint24 private _deprecatedFeeUpdateInterval;

    /**
     * @dev From first contract, only used for initialization to preserve old values
     */
    mapping(ITornadoInstance => uint160) internal _oldFeesForInstance;

    /**
     * @dev From first contract, only used for initialization to preserve old values
     */
    mapping(ITornadoInstance => uint256) internal _oldFeesForInstanceUpdateTime;
}

/**
 * @title FeeOracleManager
 * @author AlienTornadosaurusHex
 * @notice A contract which manages fee oracles and received data for other contracts to consume.
 * @dev This is an improved version of the FeeManager with a modified design from the original contract.
 */
contract FeeOracleManager is FeeManagerLegacyStorage, Initializable {
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ PARAMS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /**
     * @notice Divide protocol fee by this to get the percent value
     */
    uint32 public constant FEE_PERCENT_DIVISOR = 10_000;

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ACCESS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /**
     * @notice Governance is allowed to access most setters
     */
    address public immutable governanceProxyAddress;

    /**
     * @notice The contract which is allowed to update instance fees
     */
    address public feeUpdaterAddress;

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ OTHER ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /**
     * @notice The TORN token
     */
    IERC20 public immutable torn;

    /**
     * @notice The InstanceRegistry contract
     */
    InstanceRegistry public instanceRegistry;

    /**
     * @notice Each instance has a dedicated fee oracle, these only compute the values
     */
    mapping(ITornadoInstance => IFeeOracle) public instanceFeeOracles;

    /**
     * @notice The data for each instance will be stored in this contract
     */
    mapping(ITornadoInstance => FeeData) public feesByInstance;

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ EVENTS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    event FeeUpdated(address indexed instance, uint256 newFee);
    event FeeUpdateIntervalUpdated(uint24 newLimit);
    event InstanceFeePercentUpdated(address indexed instance, uint32 newFeePercent);

    event OracleUpdated(address indexed instance, address oracle);
    event InstanceRegistryUpdated(address newAddress);
    event FeeUpdaterUpdated(address newFeeUpdaterAddress);

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ LOGIC ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    constructor(address _governanceProxyAddress, address _tornTokenAddress) public {
        governanceProxyAddress = _governanceProxyAddress;
        torn = IERC20(_tornTokenAddress);
    }

    modifier onlyGovernance() {
        require(msg.sender == governanceProxyAddress, "FeeOracleManager: only governance");
        _;
    }

    modifier onlyFeeUpdater() {
        require(msg.sender == feeUpdaterAddress, "FeeOracleManager: only fee updater");
        _;
    }

    function version() public pure virtual returns (string memory) {
        return "v2-infrastructure-upgrade";
    }

    /**
     * @dev If there will be a need to initialize the proxy again, simply pad storage and inherit again,
     * making sure to not reference old data anywhere.
     */
    function initialize(
        address _uniswapFeeOracle,
        address _instanceRegistryProxyAddress,
        address _feeUpdaterAddress,
        uint32 _feeUpdateInterval,
        ITornadoInstance[] memory _instances,
        uint256[] memory _percents
    ) external onlyGovernance initializer {
        // Get num of existing instances
        uint256 numInstances = _instances.length;

        for (uint256 i = 0; i < numInstances; i++) {
            // For each instance
            ITornadoInstance instance = _instances[i];

            // Store it's old data and the percent fees which will be defined in the proposal
            feesByInstance[instance] = FeeData({
                amount: _oldFeesForInstance[instance],
                percent: uint32(_percents[i]),
                updateInterval: _feeUpdateInterval,
                lastUpdateTime: uint32(_oldFeesForInstanceUpdateTime[instance])
            });

            // All old pools use the uniswap fee oracle
            instanceFeeOracles[instance] = IFeeOracle(_uniswapFeeOracle);
        }

        // Store the fee updater
        feeUpdaterAddress = _feeUpdaterAddress;

        // Finally also store the instance registry
        instanceRegistry = InstanceRegistry(_instanceRegistryProxyAddress);
    }

    function updateAllFees(bool _respectFeeUpdateInterval)
        public
        virtual
        returns (uint160[] memory newFees)
    {
        return updateFees(instanceRegistry.getAllInstances(), _respectFeeUpdateInterval);
    }

    function updateFees(ITornadoInstance[] memory _instances, bool _respectFeeUpdateInterval)
        public
        virtual
        returns (uint160[] memory newFees)
    {
        uint256 numInstances = _instances.length;

        newFees = new uint160[](numInstances);

        for (uint256 i = 0; i < numInstances; i++) {
            newFees[i] = updateFee(_instances[i], _respectFeeUpdateInterval);
        }
    }

    function updateFee(ITornadoInstance _instance, bool _respectFeeUpdateInterval)
        public
        virtual
        onlyFeeUpdater
        returns (uint160)
    {
        // Get fee data & oracle
        FeeData memory fee = feesByInstance[_instance];
        IFeeOracle oracle = instanceFeeOracles[_instance];

        // Check whether the instance is registered
        require(address(oracle) != address(0), "FeeOracleManager: instance has no oracle");

        // Now update if we do not respect the interval or we respect it and are in the interval
        if (!_respectFeeUpdateInterval || (fee.updateInterval <= now - fee.lastUpdateTime)) {
            // Prepare data for the process
            InstanceWithFee memory _feeInstance = populateInstanceWithFeeData(_instance, fee);

            // Allow oracle to update state by its own logic, oracle should be responsible for a safe impl
            oracle.update(torn, _feeInstance);

            // There must a be a fee set otherwise it's just 0
            fee.amount = fee.percent != 0 ? oracle.getFee(torn, _feeInstance) : 0;

            // Store
            feesByInstance[_instance] = FeeData({
                amount: fee.amount,
                percent: fee.percent,
                updateInterval: fee.updateInterval,
                lastUpdateTime: uint32(now)
            });

            // Log
            emit FeeUpdated(address(_instance), fee.amount);
        }

        return fee.amount;
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ SETTERS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    function setFeeOracle(address _instanceAddress, address _oracleAddress) external onlyGovernance {
        // Prepare all contracts
        ITornadoInstance instance = ITornadoInstance(_instanceAddress);
        IFeeOracle oracle = IFeeOracle(_oracleAddress);

        // Instance must be enabled otherwise below won't work
        require(instanceRegistry.isEnabledInstance(instance), "FeeOracleManager: instance not enabled");

        // Nominally fee percent should be set first for an instance, but we cannot be sure
        // whether fee percent 0 is intentional, so we don't check
        FeeData memory fee = feesByInstance[instance];

        // An address(0) oracle means we're removing an oracle for an instance
        if (_oracleAddress != address(0)) {
            // Prepare data for the process
            InstanceWithFee memory _feeInstance = populateInstanceWithFeeData(instance, fee);

            // Reverts if oracle doesn't implement
            oracle.update(torn, _feeInstance);

            // Reverts if oracle doesn't implement
            fee.amount = oracle.getFee(torn, _feeInstance);

            // Note down updated fee
            feesByInstance[instance] = FeeData({
                amount: fee.amount,
                percent: fee.percent,
                updateInterval: fee.updateInterval,
                lastUpdateTime: uint32(now)
            });

            // Log fee update
            emit FeeUpdated(_instanceAddress, fee.amount);
        }

        // Ok, set the oracle
        instanceFeeOracles[instance] = oracle;

        // Log oracle update
        emit OracleUpdated(_instanceAddress, _oracleAddress);
    }

    function setFeePercentForInstance(ITornadoInstance _instance, uint32 _newFeePercent)
        external
        onlyGovernance
    {
        feesByInstance[_instance].percent = _newFeePercent;
        emit InstanceFeePercentUpdated(address(_instance), _newFeePercent);
    }

    function setFeeUpdateIntervalForInstance(ITornadoInstance _instance, uint24 newLimit)
        external
        onlyGovernance
    {
        feesByInstance[_instance].updateInterval = newLimit;
        emit FeeUpdateIntervalUpdated(newLimit);
    }

    function setInstanceRegistry(address _newInstanceRegistryProxyAddress) external onlyGovernance {
        instanceRegistry = InstanceRegistry(_newInstanceRegistryProxyAddress);
        emit InstanceRegistryUpdated(_newInstanceRegistryProxyAddress);
    }

    function setFeeUpdater(address _newFeeUpdaterAddress) external onlyGovernance {
        feeUpdaterAddress = _newFeeUpdaterAddress;
        emit FeeUpdaterUpdated(_newFeeUpdaterAddress);
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ GETTERS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    function getUpdatedFeeForInstance(ITornadoInstance instance) public view virtual returns (uint160) {
        return instanceFeeOracles[instance].getFee(torn, populateInstanceWithFeeData(instance));
    }

    function populateInstanceWithFeeData(ITornadoInstance _regularInstance)
        public
        view
        virtual
        returns (InstanceWithFee memory)
    {
        return populateInstanceWithFeeData(_regularInstance, feesByInstance[_regularInstance]);
    }

    function populateInstanceWithFeeData(ITornadoInstance _regularInstance, FeeData memory _fee)
        public
        view
        virtual
        returns (InstanceWithFee memory)
    {
        return InstanceWithFee({
            logic: _regularInstance,
            state: instanceRegistry.getInstanceState(_regularInstance),
            fee: FeeDataForOracle({
                amount: _fee.amount,
                percent: _fee.percent,
                divisor: FEE_PERCENT_DIVISOR,
                updateInterval: _fee.updateInterval,
                lastUpdateTime: _fee.lastUpdateTime
            })
        });
    }

    function getLastFeeForInstance(ITornadoInstance instance) public view virtual returns (uint160) {
        return feesByInstance[instance].amount;
    }

    function getLastUpdatedTimeForInstance(ITornadoInstance instance) public view virtual returns (uint32) {
        return feesByInstance[instance].lastUpdateTime;
    }

    function getFeePercentForInstance(ITornadoInstance instance) public view virtual returns (uint32) {
        return feesByInstance[instance].percent;
    }

    function getFeeUpdateIntervalForInstance(ITornadoInstance instance)
        public
        view
        virtual
        returns (uint32)
    {
        return feesByInstance[instance].updateInterval;
    }

    function getAllFeeDeviations() public view virtual returns (int256[] memory) {
        return getFeeDeviationsForInstances(instanceRegistry.getAllInstances());
    }

    function getFeeDeviationsForInstances(ITornadoInstance[] memory _instances)
        public
        view
        virtual
        returns (int256[] memory deviations)
    {
        uint256 numInstances = _instances.length;

        deviations = new int256[](numInstances);

        for (uint256 i = 0; i < numInstances; i++) {
            ITornadoInstance instance = _instances[i];

            FeeData memory fee = feesByInstance[instance];

            uint256 marketFee =
                instanceFeeOracles[instance].getFee(torn, populateInstanceWithFeeData(instance, fee));

            if (marketFee != 0) {
                deviations[i] = int256((fee.amount * 1000) / marketFee) - 1000;
            }
        }
    }
}