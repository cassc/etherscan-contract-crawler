// SPDX-License-Identifier: ISC
pragma solidity ^0.8.18;

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
    using Strings for uint256;
    using SafeERC20 for IERC20;

    // Storage
    address public contractAddress1;
    address public contractAddress2;

    // Admin contracts
    address public circuitBreakerAddress;
    address public comptrollerAddress;
    address public timelockAddress;
    address public fraxlendPairRegistryAddress;
    address public fraxlendWhitelistAddress;

    // Default swappers
    address[] public defaultSwappers;

    /// @notice Emits when a new pair is deployed
    /// @notice The ```LogDeploy``` event is emitted when a new Pair is deployed
    /// @param address_ The address of the pair
    /// @param asset The address of the Asset Token contract
    /// @param collateral The address of the Collateral Token contract
    /// @param name The name of the Pair
    /// @param configData The config data of the Pair
    /// @param immutables The immutables of the Pair
    /// @param customConfigData The custom config data of the Pair
    event LogDeploy(
        address indexed address_,
        address indexed asset,
        address indexed collateral,
        string name,
        bytes configData,
        bytes immutables,
        bytes customConfigData
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
        circuitBreakerAddress = _circuitBreaker;
        comptrollerAddress = _comptroller;
        timelockAddress = _timelock;
        fraxlendWhitelistAddress = _fraxlendWhitelist;
        fraxlendPairRegistryAddress = _fraxlendPairRegistry;
    }

    function version() external pure returns (uint256 _major, uint256 _minor, uint256 _patch) {
        return (4, 0, 0);
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

    function getNextNameSymbol(
        address _asset,
        address _collateral
    ) public view returns (string memory _name, string memory _symbol) {
        uint256 _length = IFraxlendPairRegistry(fraxlendPairRegistryAddress).deployedPairsLength();
        _name = string(
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
        _symbol = string(
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

    /// @notice The ```SetTimelock``` event is emitted when the timelockAddress is set
    /// @param oldAddress The original address
    /// @param newAddress The new address
    event SetTimelock(address oldAddress, address newAddress);

    /// @notice The ```setTimelock``` function sets the timelockAddress
    /// @param _newAddress the new time lock address
    function setTimelock(address _newAddress) external onlyOwner {
        emit SetTimelock(timelockAddress, _newAddress);
        timelockAddress = _newAddress;
    }

    /// @notice The ```SetRegistry``` event is emitted when the fraxlendPairRegistryAddress is set
    /// @param oldAddress The old address
    /// @param newAddress The new address
    event SetRegistry(address oldAddress, address newAddress);

    /// @notice The ```setRegistry``` function sets the fraxlendPairRegistryAddress
    /// @param _newAddress The new address
    function setRegistry(address _newAddress) external onlyOwner {
        emit SetRegistry(fraxlendPairRegistryAddress, _newAddress);
        fraxlendPairRegistryAddress = _newAddress;
    }

    /// @notice The ```SetComptroller``` event is emitted when the comptrollerAddress is set
    /// @param oldAddress The old address
    /// @param newAddress The new address
    event SetComptroller(address oldAddress, address newAddress);

    /// @notice The ```setComptroller``` function sets the comptrollerAddress
    /// @param _newAddress The new address
    function setComptroller(address _newAddress) external onlyOwner {
        emit SetComptroller(comptrollerAddress, _newAddress);
        comptrollerAddress = _newAddress;
    }

    /// @notice The ```SetWhitelist``` event is emitted when the fraxlendWhitelistAddress is set
    /// @param oldAddress The old address
    /// @param newAddress The new address
    event SetWhitelist(address oldAddress, address newAddress);

    /// @notice The ```setWhitelist``` function sets the fraxlendWhitelistAddress
    /// @param _newAddress The new address
    function setWhitelist(address _newAddress) external onlyOwner {
        emit SetWhitelist(fraxlendWhitelistAddress, _newAddress);
        fraxlendWhitelistAddress = _newAddress;
    }

    /// @notice The ```SetCircuitBreaker``` event is emitted when the circuitBreakerAddress is set
    /// @param oldAddress The old address
    /// @param newAddress The new address
    event SetCircuitBreaker(address oldAddress, address newAddress);

    /// @notice The ```setCircuitBreaker``` function sets the circuitBreakerAddress
    /// @param _newAddress The new address
    function setCircuitBreaker(address _newAddress) external onlyOwner {
        emit SetCircuitBreaker(circuitBreakerAddress, _newAddress);
        circuitBreakerAddress = _newAddress;
    }

    // ============================================================================================
    // Functions: Internal Methods
    // ============================================================================================

    /// @notice The ```_deploy``` function is an internal function with deploys the pair
    /// @param _configData abi.encode(address _asset, address _collateral, address _oracle, uint32 _maxOracleDeviation, address _rateContract, uint64 _fullUtilizationRate, uint256 _maxLTV, uint256 _cleanLiquidationFee, uint256 _dirtyLiquidationFee, uint256 _protocolLiquidationFee)
    /// @param _immutables abi.encode(address _circuitBreakerAddress, address _comptrollerAddress, address _timelockAddress)
    /// @param _customConfigData abi.encode(string memory _nameOfContract, string memory _symbolOfContract, uint8 _decimalsOfContract)
    /// @return _pairAddress The address to which the Pair was deployed
    function _deploy(
        bytes memory _configData,
        bytes memory _immutables,
        bytes memory _customConfigData
    ) private returns (address _pairAddress) {
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

        return _pairAddress;
    }

    // ============================================================================================
    // Functions: External Deploy Methods
    // ============================================================================================

    /// @notice The ```deploy``` function allows the deployment of a FraxlendPair with default values
    /// @param _configData abi.encode(address _asset, address _collateral, address _oracle, uint32 _maxOracleDeviation, address _rateContract, uint64 _fullUtilizationRate, uint256 _maxLTV, uint256 _cleanLiquidationFee, uint256 _dirtyLiquidationFee, uint256 _protocolLiquidationFee)
    /// @return _pairAddress The address to which the Pair was deployed
    function deploy(bytes memory _configData) external returns (address _pairAddress) {
        if (!IFraxlendWhitelist(fraxlendWhitelistAddress).fraxlendDeployerWhitelist(msg.sender))
            revert WhitelistedDeployersOnly();

        (address _asset, address _collateral, , , , , , , ) = abi.decode(
            _configData,
            (address, address, address, uint32, address, uint64, uint256, uint256, uint256)
        );

        (string memory _name, string memory _symbol) = getNextNameSymbol(_asset, _collateral);

        bytes memory _immutables = abi.encode(circuitBreakerAddress, comptrollerAddress, timelockAddress);
        bytes memory _customConfigData = abi.encode(_name, _symbol, IERC20(_asset).safeDecimals());

        _pairAddress = _deploy(_configData, _immutables, _customConfigData);

        IFraxlendPairRegistry(fraxlendPairRegistryAddress).addPair(_pairAddress);

        emit LogDeploy(_pairAddress, _asset, _collateral, _name, _configData, _immutables, _customConfigData);
    }

    // ============================================================================================
    // Functions: Admin
    // ============================================================================================

    /// @notice The ```globalPause``` function calls the pause() function on a given set of pair addresses
    /// @dev Ignores reverts when calling pause()
    /// @param _addresses Addresses to attempt to pause()
    /// @return _updatedAddresses Addresses for which pause() was successful
    function globalPause(address[] memory _addresses) external returns (address[] memory _updatedAddresses) {
        if (msg.sender != circuitBreakerAddress) revert CircuitBreakerOnly();

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
    error Create2Failed();
}