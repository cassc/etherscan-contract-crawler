// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/libraries/errors/AdminErrors.sol";

abstract contract Admin {
    // _admin is a privileged role
    address internal _admin;

    /// @dev onlyAdmin enforces msg.sender is _admin
    modifier onlyAdmin() {
        if (msg.sender != _admin) {
            revert AdminErrors.SenderNotAdmin(msg.sender);
        }
        _;
    }

    constructor(address admin_) {
        _admin = admin_;
    }

    /// @dev assigns a new admin may only be called by _admin
    function setAdmin(address admin_) public virtual onlyAdmin {
        _setAdmin(admin_);
    }

    /// @dev getAdmin returns the current _admin
    function getAdmin() public view returns (address) {
        return _admin;
    }

    // assigns a new admin may only be called by _admin
    function _setAdmin(address admin_) internal {
        _admin = admin_;
    }
}