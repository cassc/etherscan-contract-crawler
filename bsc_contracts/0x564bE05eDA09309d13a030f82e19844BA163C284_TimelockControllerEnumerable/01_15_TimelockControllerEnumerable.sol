// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/governance/TimelockController.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract TimelockControllerEnumerable is TimelockController, AccessControlEnumerable {
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors, address admin)
        TimelockController(minDelay, proposers, executors, admin) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(TimelockController, AccessControlEnumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _revokeRole(bytes32 role, address account) internal virtual override(AccessControl, AccessControlEnumerable) {
        return super._revokeRole(role, account);
    }

    function _grantRole(bytes32 role, address account) internal virtual override(AccessControl, AccessControlEnumerable) {
        return super._grantRole(role, account);
    }
}