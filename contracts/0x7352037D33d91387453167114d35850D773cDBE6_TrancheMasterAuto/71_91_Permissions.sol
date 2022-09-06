// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Permissions is AccessControl {
    bytes32 public constant GOVERN_ROLE = keccak256("GOVERN_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");
    bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");
    bytes32 public constant MULTISTRATEGY_ROLE = keccak256("MULTISTRATEGY_ROLE");

    constructor() public {
        _setupGovernor(address(this));
        _setRoleAdmin(GOVERN_ROLE, GOVERN_ROLE);
        _setRoleAdmin(GUARDIAN_ROLE, GOVERN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, GOVERN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, GOVERN_ROLE);
        _setRoleAdmin(MASTER_ROLE, GOVERN_ROLE);
        _setRoleAdmin(TIMELOCK_ROLE, GOVERN_ROLE);
        _setRoleAdmin(MULTISTRATEGY_ROLE, GOVERN_ROLE);
    }

    modifier onlyGovernor() {
        require(isGovernor(msg.sender), "Permissions::onlyGovernor: Caller is not a governor");
        _;
    }

    function createRole(bytes32 role, bytes32 adminRole) external onlyGovernor {
        _setRoleAdmin(role, adminRole);
    }

    function grantGovernor(address governor) external onlyGovernor {
        grantRole(GOVERN_ROLE, governor);
    }

    function grantGuardian(address guardian) external onlyGovernor {
        grantRole(GUARDIAN_ROLE, guardian);
    }

    function grantMultistrategy(address multistrategy) external onlyGovernor {
        grantRole(MULTISTRATEGY_ROLE, multistrategy);
    }

    function revokeGovernor(address governor) external onlyGovernor {
        revokeRole(GOVERN_ROLE, governor);
    }

    function revokeGuardian(address guardian) external onlyGovernor {
        revokeRole(GUARDIAN_ROLE, guardian);
    }

    function revokeMultistrategy(address multistrategy) external onlyGovernor {
        revokeRole(MULTISTRATEGY_ROLE, multistrategy);
    }

    function isGovernor(address _address) public view virtual returns (bool) {
        return hasRole(GOVERN_ROLE, _address);
    }

    function isMultistrategy(address _address) public view virtual returns (bool) {
        return hasRole(MULTISTRATEGY_ROLE, _address);
    }

    function isGuardian(address _address) public view returns (bool) {
        return hasRole(GUARDIAN_ROLE, _address);
    }

    function _setupGovernor(address governor) internal {
        _setupRole(GOVERN_ROLE, governor);
    }
}