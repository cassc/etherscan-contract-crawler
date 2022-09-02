// SPDX-License-Identifier: ISC
pragma solidity ^0.8.16;

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

    address private contractAddress1;
    address private contractAddress2;

    // Admin contracts
    address public CIRCUIT_BREAKER_ADDRESS;
    address public COMPTROLLER_ADDRESS;
    address public TIME_LOCK_ADDRESS;

    // Dependencies
    address public immutable FRAXLEND_WHITELIST_ADDRESS;

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

    /// @notice CREATE2 salt => deployed address
    mapping(bytes32 => address) public deployedPairsBySalt;
    /// @notice hash of name => deployed address
    mapping(string => address) public deployedPairsByName;
    /// @notice address => isCustom boolean
    mapping(address => bool) public deployedPairCustomStatusByAddress;
    /// @notice List of the names of all deployed Pairs
    string[] public deployedPairsArray;

    constructor(
        address _circuitBreaker,
        address _comptroller,
        address _timelock,
        address _fraxlendWhitelist
    ) Ownable() {
        CIRCUIT_BREAKER_ADDRESS = _circuitBreaker;
        COMPTROLLER_ADDRESS = _comptroller;
        TIME_LOCK_ADDRESS = _timelock;
        FRAXLEND_WHITELIST_ADDRESS = _fraxlendWhitelist;
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
    /// @return memory All deployed pair addresses
    function getAllPairAddresses() external view returns (address[] memory) {
        string[] memory _deployedPairsArray = deployedPairsArray;
        uint256 _lengthOfArray = _deployedPairsArray.length;
        address[] memory _addresses = new address[](_lengthOfArray);
        uint256 i;
        for (i = 0; i < _lengthOfArray; ) {
            _addresses[i] = deployedPairsByName[_deployedPairsArray[i]];
            unchecked {
                i++;
            }
        }
        return _addresses;
    }

    struct PairCustomStatus {
        address _address;
        bool _isCustom;
    }

    /// @notice The ```getCustomStatuses``` function returns an array of structs which contain the address and custom status
    /// @param _addresses Addresses to check for custom status
    /// @return _pairCustomStatuses memory Array of structs containing information
    function getCustomStatuses(address[] calldata _addresses)
        external
        view
        returns (PairCustomStatus[] memory _pairCustomStatuses)
    {
        uint256 _lengthOfArray = _addresses.length;
        uint256 i;
        _pairCustomStatuses = new PairCustomStatus[](_lengthOfArray);
        for (i = 0; i < _lengthOfArray; ) {
            _pairCustomStatuses[i] = PairCustomStatus({
                _address: _addresses[i],
                _isCustom: deployedPairCustomStatusByAddress[_addresses[i]]
            });
            unchecked {
                i++;
            }
        }
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

    /// @notice The ```SetDefaultTimeLock``` event fires when the TIME_LOCK_ADDRESS is set
    /// @param _oldAddress The original address
    /// @param _newAddress The new address
    event SetTimeLock(address _oldAddress, address _newAddress);

    /// @notice The ```setTimeLock``` function sets the TIME_LOCK address
    /// @param _newAddress the new time lock address
    function setDefaultTimeLock(address _newAddress) external onlyOwner {
        emit SetTimeLock(TIME_LOCK_ADDRESS, _newAddress);
        TIME_LOCK_ADDRESS = _newAddress;
    }

    // ============================================================================================
    // Functions: Internal Methods
    // ============================================================================================

    /// @notice The ```_deployFirst``` function is an internal function with deploys the pair
    /// @param _configData abi.encode(address _asset, address _collateral, address _oracleMultiply, address _oracleDivide, uint256 _oracleNormalization, address _rateContract, bytes memory _rateInitData)
    /// @param _maxLTV The Maximum Loan-To-Value for a borrower to be considered solvent (1e5 precision)
    /// @param _liquidationFee The fee paid to liquidators given as a % of the repayment (1e5 precision)
    /// @param _maturityDate The maturityDate of the Pair
    /// @param _isBorrowerWhitelistActive Enables borrower whitelist
    /// @param _isLenderWhitelistActive Enables lender whitelist
    /// @return _pairAddress The address to which the Pair was deployed
    function _deployFirst(
        bytes32 _saltSeed,
        bytes memory _configData,
        bytes memory _immutables,
        uint256 _maxLTV,
        uint256 _liquidationFee,
        uint256 _maturityDate,
        uint256 _penaltyRate,
        bool _isBorrowerWhitelistActive,
        bool _isLenderWhitelistActive
    ) private returns (address _pairAddress) {
        {
            // _saltSeed is the same for all public pairs so duplicates cannot be created
            bytes32 salt = keccak256(abi.encodePacked(_saltSeed, _configData));
            require(deployedPairsBySalt[salt] == address(0), "FraxlendPairDeployer: Pair already deployed");

            bytes memory _creationCode = BytesLib.concat(
                SSTORE2.read(contractAddress1),
                SSTORE2.read(contractAddress2)
            );
            bytes memory bytecode = abi.encodePacked(
                _creationCode,
                abi.encode(
                    _configData,
                    _immutables,
                    _maxLTV,
                    _liquidationFee,
                    _maturityDate,
                    _penaltyRate,
                    _isBorrowerWhitelistActive,
                    _isLenderWhitelistActive
                )
            );

            assembly {
                _pairAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
            }
            require(_pairAddress != address(0), "FraxlendPairDeployer: create2 failed");

            deployedPairsBySalt[salt] = _pairAddress;
        }

        return _pairAddress;
    }

    /// @notice The ```_deploySecond``` function is the second part of deployment, it invoked the initialize() on the Pair
    /// @param _name The name of the Pair
    /// @param _pairAddress The address of the Pair
    /// @param _configData abi.encode(address _asset, address _collateral, address _oracleMultiply, address _oracleDivide, uint256 _oracleNormalization, address _rateContract, bytes memory _rateInitData)
    /// @param _approvedBorrowers An array of approved borrower addresses
    /// @param _approvedLenders An array of approved lender addresses
    function _deploySecond(
        string memory _name,
        address _pairAddress,
        bytes memory _configData,
        address[] memory _approvedBorrowers,
        address[] memory _approvedLenders
    ) private {
        (, , , , , , bytes memory _rateInitData) = abi.decode(
            _configData,
            (address, address, address, address, uint256, address, bytes)
        );
        require(deployedPairsByName[_name] == address(0), "FraxlendPairDeployer: Pair name must be unique");
        deployedPairsByName[_name] = _pairAddress;
        deployedPairsArray.push(_name);

        // Set additional values for FraxlendPair
        IFraxlendPair _fraxlendPair = IFraxlendPair(_pairAddress);
        _fraxlendPair.initialize(_name, _approvedBorrowers, _approvedLenders, _rateInitData);
        address[] memory _defaultSwappers = defaultSwappers;
        for (uint256 i = 0; i < _defaultSwappers.length; i++) {
            _fraxlendPair.setSwapper(_defaultSwappers[i], true);
        }

        // Transfer Ownership of FraxlendPair
        _fraxlendPair.transferOwnership(COMPTROLLER_ADDRESS);
    }

    /// @notice The ```_logDeploy``` function emits a LogDeploy event
    /// @param _name The name of the Pair
    /// @param _pairAddress The address of the Pair
    /// @param _configData abi.encode(address _asset, address _collateral, address _oracleMultiply, address _oracleDivide, uint256 _oracleNormalization, address _rateContract, bytes memory _rateInitData)
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

        ) = abi.decode(_configData, (address, address, address, address, uint256, address, bytes));
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

    /// @notice The ```deploy``` function allows anyone to create a custom lending market between an Asset and Collateral Token
    /// @param _configData abi.encode(address _asset, address _collateral, address _oracleMultiply, address _oracleDivide, uint256 _oracleNormalization, address _rateContract, bytes memory _rateInitData)
    /// @return _pairAddress The address to which the Pair was deployed
    function deploy(bytes memory _configData) external returns (address _pairAddress) {
        (address _asset, address _collateral, , , , address _rateContract, ) = abi.decode(
            _configData,
            (address, address, address, address, uint256, address, bytes)
        );
        string memory _name = string(
            abi.encodePacked(
                "FraxlendV1 - ",
                IERC20(_collateral).safeName(),
                "/",
                IERC20(_asset).safeName(),
                " - ",
                IRateCalculator(_rateContract).name(),
                " - ",
                (deployedPairsArray.length + 1).toString()
            )
        );

        _pairAddress = _deployFirst(
            keccak256(abi.encodePacked("public")),
            _configData,
            abi.encode(CIRCUIT_BREAKER_ADDRESS, COMPTROLLER_ADDRESS, TIME_LOCK_ADDRESS, FRAXLEND_WHITELIST_ADDRESS),
            DEFAULT_MAX_LTV,
            DEFAULT_LIQ_FEE,
            0,
            0,
            false,
            false
        );

        _deploySecond(_name, _pairAddress, _configData, new address[](0), new address[](0));

        _logDeploy(_name, _pairAddress, _configData, DEFAULT_MAX_LTV, DEFAULT_LIQ_FEE, 0);
    }

    /// @notice The ```deployCustom``` function allows whitelisted users to deploy custom Term Sheets for OTC debt structuring
    /// @dev Caller must be added to FraxLedWhitelist
    /// @param _name The name of the Pair
    /// @param _configData abi.encode(address _asset, address _collateral, address _oracleMultiply, address _oracleDivide, uint256 _oracleNormalization, address _rateContract, bytes memory _rateInitData)
    /// @param _maxLTV The Maximum Loan-To-Value for a borrower to be considered solvent (1e5 precision)
    /// @param _liquidationFee The fee paid to liquidators given as a % of the repayment (1e5 precision)
    /// @param _maturityDate The maturityDate of the Pair
    /// @param _approvedBorrowers An array of approved borrower addresses
    /// @param _approvedLenders An array of approved lender addresses
    /// @return _pairAddress The address to which the Pair was deployed
    function deployCustom(
        string memory _name,
        bytes memory _configData,
        uint256 _maxLTV,
        uint256 _liquidationFee,
        uint256 _maturityDate,
        uint256 _penaltyRate,
        address[] memory _approvedBorrowers,
        address[] memory _approvedLenders
    ) external returns (address _pairAddress) {
        require(_maxLTV <= GLOBAL_MAX_LTV, "FraxlendPairDeployer: _maxLTV is too large");
        require(
            IFraxlendWhitelist(FRAXLEND_WHITELIST_ADDRESS).fraxlendDeployerWhitelist(msg.sender),
            "FraxlendPairDeployer: Only whitelisted addresses"
        );
        require(
            keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("public")),
            "FraxlendPairDeployer: _name parameter cannot be 'public'"
        );

        _pairAddress = _deployFirst(
            keccak256(abi.encodePacked(_name)),
            _configData,
            abi.encode(CIRCUIT_BREAKER_ADDRESS, COMPTROLLER_ADDRESS, TIME_LOCK_ADDRESS, FRAXLEND_WHITELIST_ADDRESS),
            _maxLTV,
            _liquidationFee,
            _maturityDate,
            _penaltyRate,
            _approvedBorrowers.length > 0,
            _approvedLenders.length > 0
        );

        _deploySecond(_name, _pairAddress, _configData, _approvedBorrowers, _approvedLenders);

        deployedPairCustomStatusByAddress[_pairAddress] = true;

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
        require(msg.sender == CIRCUIT_BREAKER_ADDRESS, "Circuit Breaker only");
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
}