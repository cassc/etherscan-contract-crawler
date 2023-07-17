// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./PermissionAdmin.sol";


abstract contract PermissionOperators is PermissionAdmin {
    uint256 private constant MAX_GROUP_SIZE = 50;

    mapping(address => bool) internal operators;
    address[] internal operatorsGroup;

    event OperatorAdded(address newOperator, bool isAdd);

    modifier onlyOperator() {
        require(operators[msg.sender], "only operator");
        _;
    }

    function getOperators() external view returns (address[] memory) {
        return operatorsGroup;
    }

    function addOperator(address newOperator) public onlyAdmin {
        require(!operators[newOperator], "operator exists"); // prevent duplicates.
        require(operatorsGroup.length < MAX_GROUP_SIZE, "max operators");

        emit OperatorAdded(newOperator, true);
        operators[newOperator] = true;
        operatorsGroup.push(newOperator);
    }

    function removeOperator(address operator) public onlyAdmin {
        require(operators[operator], "not operator");
        operators[operator] = false;

        for (uint256 i = 0; i < operatorsGroup.length; ++i) {
            if (operatorsGroup[i] == operator) {
                operatorsGroup[i] = operatorsGroup[operatorsGroup.length - 1];
                operatorsGroup.pop();
                emit OperatorAdded(operator, false);
                break;
            }
        }
    }
}