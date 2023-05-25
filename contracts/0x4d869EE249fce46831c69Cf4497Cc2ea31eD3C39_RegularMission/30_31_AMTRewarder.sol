// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IRewarder.sol";
import "../AMTManager/IAMTManager.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AMTRewarder is IRewarder, AccessControl {
    bytes32 public constant ADMIN = "ADMIN";
    bytes32 public constant OPERATOR = "OPERATOR";

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(OPERATOR, ADMIN);
        _grantRole(ADMIN, msg.sender);
    }

    IAMTManager public amtManager;

    function reward(address to, uint256 amount) external onlyRole(OPERATOR) {
        amtManager.add(to, amount);
    }

    function setAmtManager(address value) external onlyRole(ADMIN) {
        amtManager = IAMTManager(value);
    }

}