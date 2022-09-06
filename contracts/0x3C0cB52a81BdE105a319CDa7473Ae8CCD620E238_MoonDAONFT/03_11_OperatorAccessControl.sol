//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IOperatorAccessControl.sol";

contract OperatorAccessControl is IOperatorAccessControl, Ownable {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    modifier isOperatorOrOwner() {
        address _sender = _msgSender();
        require(
            isOperator(_sender) || owner() == _sender,
            "OperatorAccessControl: caller is not operator or owner"
        );
        _;
    }

    modifier onlyOperator() {
        require(
            isOperator(_msgSender()),
            "OperatorAccessControl: caller is not operator"
        );
        _;
    }

    function isOperator(address account) public view override returns (bool) {
        return hasRole(OPERATOR_ROLE, account);
    }

    function addOperator(address account) public override onlyOwner {
        _grantRole(OPERATOR_ROLE, account);
    }

    function revokeOperator(address account) public override onlyOwner {
        _revokeRole(OPERATOR_ROLE, account);
    }
}