// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract KRoles is AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    constructor() {
        /// Note, given that it is possible for both the DEFAULT_ADMIN_ROLE and OPERATOR_ROLE to renounce their roles,
        /// the contract can reach a state where there are not operators or admins. Users of inherting contracts should
        /// be sure to avoid reaching this state, as they will be permanently locked out of using any functions relying
        /// on the `onlyOperator` modifier for access control.
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
        _setRoleAdmin (OPERATOR_ROLE, DEFAULT_ADMIN_ROLE) ;
    }

    modifier onlyOperator() {
        require(isOperator(_msgSender()), "OperatorRole: caller does not have the Operator role");
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return hasRole(OPERATOR_ROLE, account);
    }

    function addOperator(address account) public {
        _addOperator(account);
    }

    /** @notice Renounces operator role of msg.sender. Note that it is possible for all operators to be renounced, which
      * will lock functions relying on the `onlyOperator` modifier for access control.
      */
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