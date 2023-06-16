pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

/**
 *
 * This code is part of pjf project (https://pjf.one).
 * Developed by Jagat Token (jagatoken.com).
 *
 */

contract HasAdmin {
    address private _admin;

    event AdminChanged(address indexed admin);

    modifier onlyAdmin {
        _onlyAdmin();
        _;
    }

    function _onlyAdmin() private view {
        require(_isAdmin(msg.sender), "Admin only");
    }

    function admin() public view returns(address) {
        return _admin;
    }

    function _setAdmin(address account) internal {
        _admin = account;
        emit AdminChanged(_admin);
    }

    function _isAdmin(address account) internal view returns(bool) {
        return account == _admin;
    }

}