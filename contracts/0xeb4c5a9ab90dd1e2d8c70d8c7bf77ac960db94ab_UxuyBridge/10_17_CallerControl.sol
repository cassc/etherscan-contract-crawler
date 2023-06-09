//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "./Context.sol";

abstract contract CallerControl is Context {
    mapping(address => bool) private _allowedCallers;

    // @dev Emitted when allowed caller is changed.
    event AllowedCallerChanged(address indexed caller, bool allowed);

    // @dev modifier to check if message sender is allowed caller
    modifier onlyAllowedCaller() {
        require(_allowedCallers[_msgSender()], "CallerControl: msgSender is not allowed to call");
        _;
    }

    function _updateAllowedCaller(address caller, bool allowed) internal {
        if (allowed) {
            _allowedCallers[caller] = true;
        } else {
            delete _allowedCallers[caller];
        }
        emit AllowedCallerChanged(caller, allowed);
    }
}