// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract Governable is AccessControl {
    bytes32 public constant GOVERNOR = bytes32("GOVERNOR");

    constructor(address _governor) {
        _grantRole(GOVERNOR, _governor);
    }

    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    function updateGovernor(address _newGovernor) external onlyGovernor {
        _revokeRole(GOVERNOR, msg.sender);
        _grantRole(GOVERNOR, _newGovernor);

        emit GovernorUpdated(msg.sender, _newGovernor);
    }

    function _onlyGovernor() private view {
        if (!hasRole(GOVERNOR, msg.sender)) {
            revert CallerIsNotGovernor();
        }
    }

    event GovernorUpdated(address _oldGovernor, address _newGovernor);

    error CallerIsNotGovernor();
}