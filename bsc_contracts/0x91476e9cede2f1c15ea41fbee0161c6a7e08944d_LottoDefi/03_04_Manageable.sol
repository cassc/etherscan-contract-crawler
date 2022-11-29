// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

abstract contract Manageable is Context {
    address payable private _manager;

    event managementTransferred(address indexed previousManager, address indexed newManager);

    constructor() {
        _transferManager(payable(_msgSender()));
    }

    modifier onlyManager() {
        _checkManager();
        _;
    }

    function manager() public view virtual returns (address) {
        return _manager;
    }

    function _checkManager() internal view virtual {
        require(manager() == _msgSender(), "Manageble: caller is not the manager");
    }

    function transferManager(address payable newManager) public virtual onlyManager {
        require(newManager != address(0), "Manager: new manager is the zero address");
        _transferManager(newManager);
    }

    function _transferManager(address payable newManager) internal virtual {
        address oldManager = _manager;
        _manager = newManager;
        emit managementTransferred(oldManager, newManager);
    }
}
