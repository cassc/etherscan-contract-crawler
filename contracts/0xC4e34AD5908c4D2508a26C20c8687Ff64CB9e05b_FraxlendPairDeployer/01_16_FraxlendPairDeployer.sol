// SPDX-License-Identifier: ISC
pragma solidity ^0.8.17;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ====================== FraxlendPairDeployer ========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett
// Sam Kazemian: https://github.com/samkazemian
// Travis Moore: https://github.com/FortisFortuna
// Jack Corddry: https://github.com/corddry
// Rich Gee: https://github.com/zer0blockchain

// ====================================================================

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@rari-capital/solmate/src/utils/SSTORE2.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";
import "./interfaces/IRateCalculator.sol";
import "./interfaces/IFraxlendWhitelist.sol";
import "./interfaces/IFraxlendPair.sol";
import "./interfaces/IFraxlendPairRegistry.sol";
import "./libraries/SafeERC20.sol";

// solhint-disable no-inline-assembly

/// @title FraxlendPairDeployer
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice Deploys and initializes new FraxlendPairs
/// @dev Uses create2 to deploy the pairs, logs an event, and records a list of all deployed pairs
contract FraxlendPairDeployer is Ownable {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    // Constants
    uint256 public DEFAULT_MAX_LTV = 75000; // 75% with 1e5 precision
    uint256 public GLOBAL_MAX_LTV = 1e8; // 1000x (100,000%) with 1e5 precision, protects from rounding errors in LTV calc
    uint256 public DEFAULT_LIQ_FEE = 10000; // 10% with 1e5 precision
    uint256 public DEFAULT_MAX_ORACLE_DELAY = 86400; // 1 hour

    address public contractAddress1;
    address public contractAddress2;

    // Admin contracts
    address public CIRCUIT_BREAKER_ADDRESS;
    address public COMPTROLLER_ADDRESS;
    address public TIME_LOCK_ADDRESS;
    address public FRAXLEND_PAIR_REGISTRY_ADDRESS;
    address public FRAXLEND_WHITELIST_ADDRESS;

    // Default swappers
    address[] public defaultSwappers;

    /// @notice Emits when a new pair is deployed
    /// @notice The ```LogDeploy``` event is emitted when a new Pair is deployed
    /// @param _name The name of the Pair
    /// @param _address The address of the pair
    /// @param _asset The address of the Asset Token contract
    /// @param _collateral The address of the Collateral Token contract
    /// @param _oracleMultiply The address of the numerator price Oracle
    /// @param _oracleDivide The address of the denominator price Oracle
    /// @param _rateContract The address of the Rate Calculator contract
    /// @param _maxLTV The Maximum Loan-To-Value for a borrower to be considered solvent (1e5 precision)
    /// @param _liquidationFee The fee paid to liquidators given as a % of the repayment (1e5 precision)
    /// @param _maturityDate The maturityDate of the Pair
    event LogDeploy(
        string indexed _name,
        address _address,
        address indexed _asset,
        address indexed _collateral,
        address _oracleMultiply,
        address _oracleDivide,
        address _rateContract,
        uint256 _maxLTV,
        uint256 _liquidationFee,
        uint256 _maturityDate
    );

    /// @notice List of the names of all deployed Pairs
    address[] public deployedPairsArray;

    constructor(
        address _circuitBreaker,
        address _comptroller,
        address _timelock,
        address _fraxlendWhitelist,
        address _fraxlendPairRegistry
    ) Ownable() {
        CIRCUIT_BREAKER_ADDRESS = _circuitBreaker;
        COMPTROLLER_ADDRESS = _comptroller;
        TIME_LOCK_ADDRESS = _timelock;
        FRAXLEND_WHITELIST_ADDRESS = _fraxlendWhitelist;
        FRAXLEND_PAIR_REGISTRY_ADDRESS = _fraxlendPairRegistry;
    }

    // ============================================================================================
    // Functions: View Functions
    // ============================================================================================

    /// @notice The ```deployedPairsLength``` function returns the length of the deployedPairsArray
    /// @return length of array
    function deployedPairsLength() external view returns (uint256) {
        return deployedPairsArray.length;
    }

    /// @notice The ```getAllPairAddresses``` function returns all pair addresses in deployedPairsArray
    /// @return _deployedPairs memory All deployed pair addresses
    function getAllPairAddresses() external view returns (address[] memory _deployedPairs) {
        _deployedPairs = deployedPairsArray;
    }

    // ============================================================================================
    // Functions: Setters
    // ============================================================================================

    /// @notice The ```setCreationCode``` function sets the bytecode for the fraxlendPair
    /// @dev splits the data if necessary to accommodate creation code that is slightly larger than 24kb
    /// @param _creationCode The creationCode for the Fraxlend Pair
    function setCreationCode(bytes calldata _creationCode) external onlyOwner {
        bytes memory _firstHalf = BytesLib.slice(_creationCode, 0, 13000);
        contractAddress1 = SSTORE2.write(_firstHalf);
        if (_creationCode.length > 13000) {
            bytes memory _secondHalf = BytesLib.slice(_creationCode, 13000, _creationCode.length - 13000);
            contractAddress2 = SSTORE2.write(_secondHalf);
        }
    }

    /// @notice The ```setDefaultSwappers``` function is used to set default list of approved swappers
    /// @param _swappers The list of swappers to set as default allowed
    function setDefaultSwappers(address[] memory _swappers) external onlyOwner {
        defaultSwappers = _swappers;
    }

    /// @notice The ```SetTimeLock``` event is emitted when the TIME_LOCK_ADDRESS is set
    /// @param _oldAddress The original address
    /// @param _newAddress The new address
    event SetTimeLock(address _oldAddress, address _newAddress);

    /// @notice The ```setTimeLock``` function sets the TIME_LOCK_ADDRESS
    /// @param _newAddress the new time lock address
    function setTimeLock(address _newAddress) external onlyOwner {
        emit SetTimeLock(TIME_LOCK_ADDRESS, _newAddress);
        TIME_LOCK_ADDRESS = _newAddress;
    }

    /// @notice The ```SetRegistry``` event is emitted when the FRAXLEND_PAIR_REGISTRY_ADDRESS is set
    /// @param _oldAddress The old address
    /// @param _newAddress The new address
    event SetRegistry(address _oldAddress, address _newAddress);

    /// @notice The ```setRegistry``` function sets the FRAXLEND_PAIR_REGISTRY_ADDRESS
    /// @param _newAddress The new address
    function setRegistry(address _newAddress) external onlyOwner {
        emit SetRegistry(FRAXLEND_PAIR_REGISTRY_ADDRESS, _newAddress);
        FRAXLEND_PAIR_REGISTRY_ADDRESS = _newAddress;
    }

    /// @notice The ```SetComptroller``` event is emitted when the COMPTROLLER_ADDRESS is set
    /// @param _oldAddress The old address
    /// @param _newAddress The new address
    event SetComptroller(address _oldAddress, address _newAddress);

    /// @notice The ```setComptroller``` function sets the COMPTROLLER_ADDRESS
    /// @param _newAddress The new address
    function setComptroller(address _newAddress) external onlyOwner {
        emit SetComptroller(COMPTROLLER_ADDRESS, _newAddress);
        COMPTROLLER_ADDRESS = _newAddress;
    }

    /// @notice The ```SetWhitelist``` event is emitted when the FRAXLEND_WHITELIST_ADDRESS is set
    /// @param _oldAddress The old address
    /// @param _newAddress The new address
    event SetWhitelist(address _oldAddress, address _newAddress);

    /// @notice The ```setWhitelist``` function sets the FRAXLEND_WHITELIST_ADDRESS
    /// @param _newAddress The new address
    function setWhitelist(address _newAddress) external onlyOwner {
        emit SetWhitelist(FRAXLEND_WHITELIST_ADDRESS, _newAddress);
        FRAXLEND_WHITELIST_ADDRESS = _newAddress;
    }

    /// @notice The ```SetCircuitBreaker``` event is emitted when the CIRCUIT_BREAKER_ADDRESS is set
    /// @param _oldAddress The old address
    /// @param _newAddress The new address
    event SetCircuitBreaker(address _oldAddress, address _newAddress);

    /// @notice The ```setCircuitBreaker``` function sets the CIRCUIT_BREAKER_ADDRESS
    /// @param _newAddress The new address
    function setCircuitBreaker(address _newAddress) external onlyOwner {
        emit SetCircuitBreaker(CIRCUIT_BREAKER_ADDRESS, _newAddress);
        CIRCUIT_BREAKER_ADDRESS = _newAddress;
    }

    /// @notice The ```SetDefaultMaxLTV``` event is emitted when the DEFAULT_MAX_LTV is set
    /// @param _oldMaxLTV The old max LTV
    /// @param _newMaxLTV The new max LTV
    event SetDefaultMaxLTV(uint256 _oldMaxLTV, uint256 _newMaxLTV);

    /// @notice The ```setDefaultMaxLTV``` function sets the DEFAULT_MAX_LTV
    /// @param _newMaxLTV The new max LTV
    function setDefaultMaxLTV(uint256 _newMaxLTV) external onlyOwner {
        emit SetDefaultMaxLTV(DEFAULT_MAX_LTV, _newMaxLTV);
        DEFAULT_MAX_LTV = _newMaxLTV;
    }

    /// @notice The ```SetDefaultLiquidationFee``` event is emitted when the DEFAULT_LIQ_FEE is set
    /// @param _oldLiquidationFee The old liquidation fee
    /// @param _newLiquidationFee The new liquidation fee
    event SetDefaultLiquidationFee(uint256 _oldLiquidationFee, uint256 _newLiquidationFee);

    /// @notice The ```setDefaultLiquidationFee``` function sets the DEFAULT_LIQ_FEE
    /// @param _newLiquidationFee The new liquidation fee
    function setDefaultLiquidationFee(uint256 _newLiquidationFee) external onlyOwner {
        emit SetDefaultLiquidationFee(DEFAULT_LIQ_FEE, _newLiquidationFee);
        DEFAULT_LIQ_FEE = _newLiquidationFee;
    }

    /// @notice The ```SetDefaultMaxOracleDelay``` event is emitted when the DEFAULT_MAX_ORACLE_DELAY is set
    /// @param _oldMaxOracleDelay The old max oracle delay
    /// @param _newMaxOracleDelay The new max oracle delay
    event SetDefaultMaxOracleDelay(uint256 _oldMaxOracleDelay, uint256 _newMaxOracleDelay);

    /// @notice The ```setDefaultMaxOracleDelay``` function sets the DEFAULT_MAX_ORACLE_DELAY
    /// @param _newMaxOracleDelay The new max oracle delay
    function setDefaultMaxOracleDelay(uint256 _newMaxOracleDelay) external onlyOwner {
        emit SetDefaultMaxOracleDelay(DEFAULT_MAX_ORACLE_DELAY, _newMaxOracleDelay);
        DEFAULT_MAX_ORACLE_DELAY = _newMaxOracleDelay;
    }

    // ============================================================================================
    // Functions: Internal Methods
    // ============================================================================================

    /// @notice The ```_deploy``` function is an internal function with deploys the pair
    /// @param _configData abi.encode(address _asset, address _collateral, address _oracleMultiply, address _oracleDivide, uint256 _oracleNormalization, address _rateContract, uint64 _fullUtilizationRate)
    /// @param _immutables abi.encode(address _circuitBreaker, address _comptrollerAddress, address _timeLockAddress, address _fraxlendWhitelistAddress)
    /// @param _customConfigData abi.encode(string _nameOfContract, string _symbolOfContract, uint8 _decimalsOfContract, uint256 _maxLTV, uint256 _liquidationFee, uint256 _maturityDate, uint256 _penaltyRate, address[] _approvedBorrowers, address[] _approvedLenders, uint256 _maxOracleDelay)
    /// @return _pairAddress The address to which the Pair was deployed
    function _deploy(bytes memory _configData, bytes memory _immutables, bytes memory _customConfigData)
        private
        returns (address _pairAddress)
    {
        // Get creation code
        bytes memory _creationCode = BytesLib.concat(SSTORE2.read(contractAddress1), SSTORE2.read(contractAddress2));

        // Get bytecode
        bytes memory bytecode = abi.encodePacked(
            _creationCode,
            abi.encode(_configData, _immutables, _customConfigData)
        );

        // Generate salt using constructor params
        bytes32 salt = keccak256(abi.encodePacked(_configData, _immutables, _customConfigData));

        /// @solidity memory-safe-assembly
        assembly {
            _pairAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        if (_pairAddress == address(0)) revert Create2Failed();

        deployedPairsArray.push(_pairAddress);

        // Set additional values for FraxlendPair
        IFraxlendPair _fraxlendPair = IFraxlendPair(_pairAddress);
        address[] memory _defaultSwappers = defaultSwappers;
        for (uint256 i = 0; i < _defaultSwappers.length; i++) {
            _fraxlendPair.setSwapper(_defaultSwappers[i], true);
        }

        // Transfer Ownership of FraxlendPair
        _fraxlendPair.transferOwnership(COMPTROLLER_ADDRESS);

        return _pairAddress;
    }

    /// @notice The ```_logDeploy``` function emits a LogDeploy event
    /// @param _name The name of the Pair
    /// @param _pairAddress The address of the Pair
    /// @param _configData abi.encode(address _asset, address _collateral, address _oracleMultiply, address _oracleDivide, uint256 _oracleNormalization, address _rateContract, uint64 _fullUtilizationRate)
    /// @param _maxLTV The Maximum Loan-To-Value for a borrower to be considered solvent (1e5 precision)
    /// @param _liquidationFee The fee paid to liquidators given as a % of the repayment (1e5 precision)
    /// @param _maturityDate The maturityDate of the Pair
    function _logDeploy(
        string memory _name,
        address _pairAddress,
        bytes memory _configData,
        uint256 _maxLTV,
        uint256 _liquidationFee,
        uint256 _maturityDate
    ) private {
        (
            address _asset,
            address _collateral,
            address _oracleMultiply,
            address _oracleDivide,
            ,
            address _rateContract,

        ) = abi.decode(_configData, (address, address, address, address, uint256, address, uint64));
        emit LogDeploy(
            _name,
            _pairAddress,
            _asset,
            _collateral,
            _oracleMultiply,
            _oracleDivide,
            _rateContract,
            _maxLTV,
            _liquidationFee,
            _maturityDate
        );
    }

    // ============================================================================================
    // Functions: External Deploy Methods
    // ============================================================================================

    /// @notice The ```deployWithDefaults``` function allows the deployment of a FraxlendPair with default values
    /// @param _configData abi.encode(address _asset, address _collateral, address _oracleMultiply, address _oracleDivide, uint256 _oracleNormalization, address _rateContract, uint64 _fullUtilizationRate)
    /// @return _pairAddress The address to which the Pair was deployed
    function deployWithDefaults(bytes memory _configData) external returns (address _pairAddress) {
        if (!IFraxlendWhitelist(FRAXLEND_WHITELIST_ADDRESS).fraxlendDeployerWhitelist(msg.sender))
            revert WhitelistedDeployersOnly();

        (address _asset, address _collateral, , , , , ) = abi.decode(
            _configData,
            (address, address, address, address, uint256, address, uint64)
        );

        uint256 _length = IFraxlendPairRegistry(FRAXLEND_PAIR_REGISTRY_ADDRESS).deployedPairsLength();
        string memory _name = string(
            abi.encodePacked(
                "Fraxlend Interest Bearing ",
                IERC20(_asset).safeSymbol(),
                " (",
                IERC20(_collateral).safeName(),
                ")",
                " - ",
                (_length + 1).toString()
            )
        );

        string memory _symbol = string(
            abi.encodePacked(
                "f",
                IERC20(_asset).safeSymbol(),
                "(",
                IERC20(_collateral).safeSymbol(),
                ")",
                "-",
                (_length + 1).toString()
            )
        );

        _pairAddress = _deploy(
            _configData,
            abi.encode(CIRCUIT_BREAKER_ADDRESS, COMPTROLLER_ADDRESS, TIME_LOCK_ADDRESS, FRAXLEND_WHITELIST_ADDRESS),
            abi.encode(
                _name,
                _symbol,
                IERC20(_asset).safeDecimals(),
                DEFAULT_MAX_LTV,
                DEFAULT_LIQ_FEE,
                0,
                0,
                new address[](0),
                new address[](0),
                DEFAULT_MAX_ORACLE_DELAY
            )
        );

        IFraxlendPairRegistry(FRAXLEND_PAIR_REGISTRY_ADDRESS).addPair(_pairAddress);

        _logDeploy(_name, _pairAddress, _configData, DEFAULT_MAX_LTV, DEFAULT_LIQ_FEE, 0);
    }

    /// @notice The ```deployCustom``` function allows whitelisted users to deploy custom Term Sheets for OTC debt structuring
    /// @dev Caller must be added to FraxLedWhitelist
    /// @param _configData abi.encode(address _asset, address _collateral, address _oracleMultiply, address _oracleDivide, uint256 _oracleNormalization, address _rateContract, uint64 _fullUtilizationRate)
    /// @param _customConfigData abi.encode(string _nameOfContract, string _symbolOfContract, uint8 _decimalsOfContract, uint256 _maxLTV, uint256 _liquidationFee, uint256 _maturityDate, uint256 _penaltyRate, address[] _approvedBorrowers, address[] _approvedLenders, uint256 _maxOracleDelay)
    /// @return _pairAddress The address to which the Pair was deployed
    function deployCustom(bytes memory _configData, bytes memory _customConfigData)
        external
        returns (address _pairAddress)
    {
        // Ensure caller has proper permissions
        if (!IFraxlendWhitelist(FRAXLEND_WHITELIST_ADDRESS).fraxlendDeployerWhitelist(msg.sender))
            revert WhitelistedDeployersOnly();

        // Decode custom config data
        (string memory _name, , , uint256 _maxLTV, uint256 _liquidationFee, uint256 _maturityDate, , , , ) = abi.decode(
            _customConfigData,
            (string, string, uint8, uint256, uint256, uint256, uint256, address[], address[], uint256)
        );

        // Checks on custom config data
        if (_maxLTV > GLOBAL_MAX_LTV) revert MaxLTVTooLarge();

        _pairAddress = _deploy(
            _configData,
            abi.encode(CIRCUIT_BREAKER_ADDRESS, COMPTROLLER_ADDRESS, TIME_LOCK_ADDRESS, FRAXLEND_WHITELIST_ADDRESS),
            _customConfigData
        );

        IFraxlendPairRegistry(FRAXLEND_PAIR_REGISTRY_ADDRESS).addPair(_pairAddress);

        _logDeploy(_name, _pairAddress, _configData, _maxLTV, _liquidationFee, _maturityDate);
    }

    // ============================================================================================
    // Functions: Admin
    // ============================================================================================

    /// @notice The ```globalPause``` function calls the pause() function on a given set of pair addresses
    /// @dev Ignores reverts when calling pause()
    /// @param _addresses Addresses to attempt to pause()
    /// @return _updatedAddresses Addresses for which pause() was successful
    function globalPause(address[] memory _addresses) external returns (address[] memory _updatedAddresses) {
        if (msg.sender != CIRCUIT_BREAKER_ADDRESS) revert CircuitBreakerOnly();

        address _pairAddress;
        uint256 _lengthOfArray = _addresses.length;
        _updatedAddresses = new address[](_lengthOfArray);
        for (uint256 i = 0; i < _lengthOfArray; ) {
            _pairAddress = _addresses[i];
            try IFraxlendPair(_pairAddress).pause() {
                _updatedAddresses[i] = _addresses[i];
            } catch {}
            unchecked {
                i = i + 1;
            }
        }
    }

    // ============================================================================================
    // Errors
    // ============================================================================================

    error CircuitBreakerOnly();
    error WhitelistedDeployersOnly();
    error MaxLTVTooLarge();
    error Create2Failed();
}