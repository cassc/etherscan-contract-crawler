pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/access/AccessControl.sol";

contract OperatorRole is AccessControl {
    
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Ownable: caller is not the admin");
        _;
    }

    modifier onlyOperator() {
        require(isOperator(_msgSender()), "Ownable: caller is not the operator");
        _;
    }

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function addOperator(address _account) public onlyAdmin {
        _setupRole(OPERATOR_ROLE , _account);
    }

    function removeOperator(address _account) public onlyAdmin {
        revokeRole(OPERATOR_ROLE , _account);
    }

    function isAdmin(address _account) internal virtual view returns(bool) {
        return hasRole(DEFAULT_ADMIN_ROLE , _account);
    }

    function isOperator(address _account) internal virtual view returns(bool) {
        return hasRole(OPERATOR_ROLE , _account);
    }
}