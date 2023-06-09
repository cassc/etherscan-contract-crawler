// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract Roles is Ownable {
    address public operatorAddress;
    address public governorAddress;

    struct RoleAssigned {
        bool operatorAssigned;
        bool governorAssigned;
    }

    RoleAssigned public roles;

    event AssignGovernorAddress(address indexed _address);
    event AssignOperatorAddress(address indexed _address);

    constructor() {}

    modifier onlyOperator() {
        require(
            roles.operatorAssigned && msg.sender == operatorAddress,
            "Only operator allowed."
        );
        _;
    }

    modifier onlyGovernor() {
        require(
            roles.governorAssigned && msg.sender == governorAddress,
            "Only governor allowed."
        );
        _;
    }

    function setOperatorAddress(address _operator) external onlyOwner {
        require(_operator != address(0));
        operatorAddress = _operator;
        roles.operatorAssigned = true;
        emit AssignOperatorAddress(_operator);
    }

    function setGovernorAddress(address _governor) external onlyOwner {
        require(_governor != address(0));
        governorAddress = _governor;
        roles.governorAssigned = true;
        emit AssignGovernorAddress(_governor);
    }
}