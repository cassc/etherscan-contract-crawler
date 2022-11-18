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
// ====================== FraxlendPairRegistry ========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett
// Rich Gee: https://github.com/zer0blockchain

// ====================================================================

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FraxlendPairRegistry is Ownable {
    /// @notice addresses of deployers allowed to add to the registry
    mapping(address => bool) public deployers;

    /// @notice List of the addresses of all deployed Pairs
    address[] public deployedPairsArray;

    /// @notice name => deployed address
    mapping(string => address) public deployedPairsByName;

    /// @notice List of all the salts of all deployed Pairs
    address[] public deployedSaltsArray;

    /// @notice salt => address
    mapping(bytes32 => address) public deployedPairsBySalt;

    constructor() Ownable() {}

    // ============================================================================================
    // Functions: View Functions
    // ============================================================================================

    /// @notice The ```deployedSaltsLength``` function returns the length of the deployedSaltsArray
    /// @return length of array
    function deployedSaltsLength() external view returns (uint256) {
        return deployedSaltsArray.length;
    }

    /// @notice The ```deployedPairsLength``` function returns the length of the deployedPairsArray
    /// @return length of array
    function deployedPairsLength() external view returns (uint256) {
        return deployedPairsArray.length;
    }

    /// @notice The ```getAllPairAddresses``` function returns an array of all deployed pairs
    /// @return _deployedPairsArray The array of pairs deployed
    function getAllPairAddresses() external view returns (address[] memory _deployedPairsArray) {
        _deployedPairsArray = deployedPairsArray;
    }

    /// @notice The ```getAllPairSalts``` function returns an array of all deployed pair salts
    /// @return _deployedSaltsArray
    function getAllPairSalts() external view returns (address[] memory _deployedSaltsArray) {
        _deployedSaltsArray = deployedSaltsArray;
    }

    // ============================================================================================
    // Functions: Setters
    // ============================================================================================

    /// @notice The ```SetDeployer``` event is called when a deployer is added or removed from the whitelist
    /// @param _deployer The address to be set
    /// @param _bool The value to set (allow or disallow)
    event SetDeployer(address _deployer, bool _bool);

    /// @notice The ```setDeployers``` function sets the deployers whitelist
    /// @param _deployers The deployers to set
    /// @param _bool The boolean to set
    function setDeployers(address[] memory _deployers, bool _bool) external onlyOwner {
        for (uint256 i = 0; i < _deployers.length; i++) {
            deployers[_deployers[i]] = _bool;
            emit SetDeployer(_deployers[i], _bool);
        }
    }

    // ============================================================================================
    // Functions: External Methods
    // ============================================================================================

    /// @notice The ```AddPair``` event is emitted when a new pair is added to the registry
    /// @param _pairAddress The address of the pair
    event AddPair(address _pairAddress);

    /// @notice The ```addPair``` function adds a pair to the registry and ensures a unique name
    /// @param _pairAddress The address of the pair
    function addPair(address _pairAddress) external {
        // Ensure caller is on the whitelist
        if (!deployers[msg.sender]) revert DeployersOnly();

        // Add pair to the global list
        deployedPairsArray.push(_pairAddress);

        // Pull name, ensure uniqueness and add to the name mapping
        string memory _name = IERC20Metadata(_pairAddress).name();
        if (deployedPairsByName[_name] != address(0)) revert NameMustBeUnique();
        deployedPairsByName[_name] = _pairAddress;

        emit AddPair(_pairAddress);
    }

    /// @notice The ```AddSalt``` event is emitted when a new pair salt is added to the registry
    /// @param _pairAddress The address of the pair
    /// @param _salt The salt of the pair
    event AddSalt(address _pairAddress, bytes32 _salt);

    /// @notice The ```addSalt``` function is called by a deployers to add a salt to the registry
    /// @param _salt Hash of configuration parameters
    /// @param _pairAddress The address of the pair
    function addSalt(address _pairAddress, bytes32 _salt) external {
        if (!deployers[msg.sender]) revert DeployersOnly();
        if (deployedPairsBySalt[_salt] != address(0)) revert SaltMustBeUnique();
        deployedPairsBySalt[_salt] = _pairAddress;
    }

    // ============================================================================================
    // Errors
    // ============================================================================================

    error DeployersOnly();
    error SaltMustBeUnique();
    error NameMustBeUnique();
}