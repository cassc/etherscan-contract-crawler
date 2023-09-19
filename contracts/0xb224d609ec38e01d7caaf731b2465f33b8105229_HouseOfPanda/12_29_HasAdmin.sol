pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

abstract contract IHasAdmin {
    // function admin() public virtual view returns (address);
    function _isAdmin(address account) internal virtual view returns (bool);
    function _setAdmin(address account) internal virtual;
}

contract HasAdmin is IHasAdmin {
    address public admin;

    event AdminChanged(address indexed admin);

    modifier onlyAdmin {
        _onlyAdmin();
        _;
    }

    function _onlyAdmin() private view {
        require(_isAdmin(msg.sender), "!admin");
    }

    // function admin() public override view returns(address) {
    //     return admin;
    // }

    function _setAdmin(address account) internal override {
        admin = account;
        emit AdminChanged(admin);
    }

    function _isAdmin(address account) internal override view returns(bool) {
        return account == admin;
    }

}