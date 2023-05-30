// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IAMTManager.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AMTManager is IAMTManager, AccessControl {
    bytes32 public constant ADMIN = "ADMIN";
    bytes32 public constant AMT_ADD_OPERATOR = "AMT_ADD_OPERATOR";
    bytes32 public constant AMT_USE_OPERATOR = "AMT_USE_OPERATOR";

    event AddedAMT(address indexed user, uint256 amount);
    event UsedAMT(address indexed user, string indexed action, uint256 amount);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(AMT_ADD_OPERATOR, ADMIN);
        _setRoleAdmin(AMT_USE_OPERATOR, ADMIN);
        _grantRole(ADMIN, msg.sender);
    }

    mapping(address => uint256) public amt;

    function add(
        address to,
        uint256 value
    ) external onlyRole(AMT_ADD_OPERATOR) {
        amt[to] += value;
        emit AddedAMT(to, value);
    }

    function use(
        address from,
        uint256 value,
        string calldata action
    ) external onlyRole(AMT_USE_OPERATOR) {
        require(
            tx.origin == from || hasRole(ADMIN, tx.origin),
            "only use myself."
        );
        require(amt[from] >= value, "not enough AMT.");

        amt[from] -= value;
        emit UsedAMT(from, action, value);
    }
}