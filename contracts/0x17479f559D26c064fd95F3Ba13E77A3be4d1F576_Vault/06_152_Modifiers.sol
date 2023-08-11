// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

//  libraries
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { DataTypes } from "./libraries/types/DataTypes.sol";

//  interfaces
import { IRegistry } from "./interfaces/opty/IRegistry.sol";
import { IModifiers } from "./interfaces/opty/IModifiers.sol";

/**
 * @title Modifiers Contract
 * @author Opty.fi
 * @notice Contract used to keep all the modifiers at one place
 * @dev Contract is used throughout the contracts expect registry contract
 */
abstract contract Modifiers is IModifiers {
    /**
     * @notice Registry contract instance address
     */
    IRegistry public registryContract;

    using Address for address;

    constructor(address _registry) internal {
        registryContract = IRegistry(_registry);
    }

    /**
     * @inheritdoc IModifiers
     */
    function setRegistry(address _registry) external override onlyOperator {
        require(_registry.isContract(), "!isContract");
        registryContract = IRegistry(_registry);
    }

    /**
     * @notice Modifier to check if the address is zero address or not
     */
    modifier onlyValidAddress() {
        _onlyValidAddress();
        _;
    }

    /**
     * @notice Modifier to check caller is governance or not
     */
    modifier onlyGovernance() {
        _onlyAuthorizedUser(registryContract.getGovernance(), "caller is not having governance");
        _;
    }

    /**
     * @notice Modifier to check caller is financeOperator or not
     */
    modifier onlyFinanceOperator() {
        _onlyAuthorizedUser(registryContract.getFinanceOperator(), "caller is not the financeOperator");
        _;
    }

    /**
     * @notice Modifier to check caller is riskOperator or not
     */
    modifier onlyRiskOperator() {
        _onlyAuthorizedUser(registryContract.getRiskOperator(), "caller is not the riskOperator");
        _;
    }

    /**
     * @notice Modifier to check caller is operator or not
     */
    modifier onlyStrategyOperator() {
        _onlyAuthorizedUser(registryContract.getStrategyOperator(), "caller is not the strategyOperator");
        _;
    }

    /**
     * @notice Modifier to check caller is operator or not
     */
    modifier onlyOperator() {
        _onlyAuthorizedUser(registryContract.getOperator(), "caller is not the operator");
        _;
    }

    /**
     * @notice Modifier to check caller is optyDistributor or not
     */
    modifier onlyOPTYDistributor() {
        _onlyAuthorizedUser(registryContract.getOPTYDistributor(), "!optyDistributor");
        _;
    }

    /**
     * @notice Modifier to check caller is registry or not
     */
    modifier onlyRegistry() {
        _onlyAuthorizedUser(address(registryContract), "!Registry Contract");
        _;
    }

    function _onlyAuthorizedUser(address authorizedUserAddress, string memory errorMessage) private view {
        require(msg.sender == authorizedUserAddress, errorMessage);
    }

    function _onlyValidAddress() private view {
        require(msg.sender != address(0), "caller is zero address");
    }
}