// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "../../utils/Context.sol";
import "../Roles.sol";

contract RecoverRole is Context {
    using Roles for Roles.Role;

    event RecovererAdded(address indexed account);
    event RecovererRemoved(address indexed account);

    Roles.Role private _recoverers;

    constructor () internal {
        _addRecoverer(_msgSender());
    }

    modifier onlyRecoverer() {
        require(isRecoverer(_msgSender()), "RecovererRole: caller does not have the Recoverer role");
        _;
    }

    function isRecoverer(address account) public view returns (bool) {
        return _recoverers.has(account);
    }

    function addRecoverer(address account) public onlyRecoverer {
        _addRecoverer(account);
    }

    function renounceRecoverer() public {
        _removeRecoverer(_msgSender());
    }

    function _addRecoverer(address account) internal {
        _recoverers.add(account);
        emit RecovererAdded(account);
    }

    function _removeRecoverer(address account) internal {
        _recoverers.remove(account);
        emit RecovererRemoved(account);
    }
}