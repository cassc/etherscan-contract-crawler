// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

//  libraries
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

//  helper contracts
import { RegistryStorageV1 } from "./RegistryStorage.sol";

//  interfaces
import { IModifiersController } from "./interfaces/opty/IModifiersController.sol";

/**
 * @title ModifiersController Contract
 * @author Opty.fi
 * @notice Contract used by registry contract and acts as source of truth
 * @dev It manages operator, optyDistributor addresses as well as modifiers
 */
abstract contract ModifiersControllerExt is IModifiersController, RegistryStorageV1 {
    using Address for address;

    /**
     * @inheritdoc IModifiersController
     */
    function setFinanceOperator(address _financeOperator) public override onlyGovernance {
        require(_financeOperator != address(0), "!address(0)");
        financeOperator = _financeOperator;
        emit TransferFinanceOperator(financeOperator, msg.sender);
    }

    /**
     * @inheritdoc IModifiersController
     */
    function setRiskOperator(address _riskOperator) public override onlyGovernance {
        require(_riskOperator != address(0), "!address(0)");
        riskOperator = _riskOperator;
        emit TransferRiskOperator(riskOperator, msg.sender);
    }

    /**
     * @inheritdoc IModifiersController
     */
    function setStrategyOperator(address _strategyOperator) public override onlyGovernance {
        require(_strategyOperator != address(0), "!address(0)");
        strategyOperator = _strategyOperator;
        emit TransferStrategyOperator(strategyOperator, msg.sender);
    }

    /**
     * @inheritdoc IModifiersController
     */
    function setOperator(address _operator) public override onlyGovernance {
        require(_operator != address(0), "!address(0)");
        operator = _operator;
        emit TransferOperator(operator, msg.sender);
    }

    /**
     * @inheritdoc IModifiersController
     */
    function setOPTYDistributor(address _optyDistributor) public override onlyGovernance {
        require(_optyDistributor.isContract(), "!isContract");
        optyDistributor = _optyDistributor;
        emit TransferOPTYDistributor(optyDistributor, msg.sender);
    }

    /**
     * @notice Modifier to check caller is governance or not
     */
    modifier onlyGovernance() {
        require(msg.sender == governance, "caller is not having governance");
        _;
    }

    /**
     * @notice Modifier to check caller is financeOperator or not
     */
    modifier onlyFinanceOperator() {
        require(msg.sender == financeOperator, "caller is not the finance operator");
        _;
    }

    /**
     * @notice Modifier to check caller is riskOperator or not
     */
    modifier onlyRiskOperator() {
        require(msg.sender == riskOperator, "caller is not the risk operator");
        _;
    }

    /**
     * @notice Modifier to check caller is operator or not
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "caller is not the operator");
        _;
    }

    /**
     * @notice Modifier to check caller is optyDistributor or not
     */
    modifier onlyOptyDistributor() {
        require(msg.sender == optyDistributor, "caller is not the optyDistributor");
        _;
    }
}