// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract KRoles is AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(OPERATOR_ROLE, _msgSender());
    }

    modifier onlyOperator() {
        require(isOperator(_msgSender()), "OperatorRole: caller does not have the Operator role");
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return hasRole(OPERATOR_ROLE, account);
    }

    function addOperator(address account) public onlyOperator {
        _addOperator(account);
    }

    function renounceOperator() public virtual {
        _renounceOperator(msg.sender);
    }

    function _addOperator(address account) internal {
        grantRole(OPERATOR_ROLE, account);
        emit OperatorAdded(account);
    }

    function _renounceOperator(address account) internal {
        renounceRole(OPERATOR_ROLE, account);
        emit OperatorRemoved(account);
    }
}