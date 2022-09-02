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
// ======================= FraxlendWhitelist ==========================
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

import "@openzeppelin/contracts/access/Ownable.sol";

contract FraxlendWhitelist is Ownable {
    // Oracle Whitelist Storage
    mapping(address => bool) public oracleContractWhitelist;

    // Interest Rate Calculator Whitelist Storage
    mapping(address => bool) public rateContractWhitelist;

    // Fraxlend Deployer Whitelist Storage
    mapping(address => bool) public fraxlendDeployerWhitelist;

    constructor() Ownable() {}

    /// @notice The ```SetOracleWhitelist``` event fires whenever a status is set for a given address
    /// @param _address address being set
    /// @param _bool approval being set
    event SetOracleWhitelist(address indexed _address, bool _bool);

    /// @notice The ```setOracleContractWhitelist``` function sets a given address to true/false for use as oracle
    /// @param _addresses addresses to set status for
    /// @param _bool status of approval
    function setOracleContractWhitelist(address[] calldata _addresses, bool _bool) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            oracleContractWhitelist[_addresses[i]] = _bool;
            emit SetOracleWhitelist(_addresses[i], _bool);
        }
    }

    /// @notice The ```SetRateContractWhitelist``` event fires whenever a status is set for a given address
    /// @param _address address being set
    /// @param _bool approval being set
    event SetRateContractWhitelist(address indexed _address, bool _bool);

    /// @notice The ```setRateContractWhitelist``` function sets a given address to true/false for use as a Rate Calculator
    /// @param _addresses addresses to set status for
    /// @param _bool status of approval
    function setRateContractWhitelist(address[] calldata _addresses, bool _bool) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            rateContractWhitelist[_addresses[i]] = _bool;
            emit SetRateContractWhitelist(_addresses[i], _bool);
        }
    }

    /// @notice The ```SetFraxlendDeployerWhitelist``` event fires whenever a status is set for a given address
    /// @param _address address being set
    /// @param _bool approval being set
    event SetFraxlendDeployerWhitelist(address indexed _address, bool _bool);

    /// @notice The ```setFraxlendDeployerWhitelist``` function sets a given address to true/false for use as a custom deployer
    /// @param _addresses addresses to set status for
    /// @param _bool status of approval
    function setFraxlendDeployerWhitelist(address[] calldata _addresses, bool _bool) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            fraxlendDeployerWhitelist[_addresses[i]] = _bool;
            emit SetFraxlendDeployerWhitelist(_addresses[i], _bool);
        }
    }
}