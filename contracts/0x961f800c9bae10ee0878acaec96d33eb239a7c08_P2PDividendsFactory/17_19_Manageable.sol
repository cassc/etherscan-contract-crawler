// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/utils/ContextUpgradeable.sol";

contract Manageable is Initializable, ContextUpgradeable {
    address private _manager;

    modifier onlyManager() {
        require(_msgSender() == _manager, "Manageable: only allowed for manager");
        _;
    }

    event ChangeManager(address indexed newManager, address indexed oldManager);

    function __Manageable_init(address manager_) internal virtual onlyInitializing {
        _manager = manager_;
        emit ChangeManager(_manager, address(0));
    }

    function setManager(address manager_) public onlyManager {
        _manager = manager_;
        emit ChangeManager(_manager, address(0));
    }

    function manager() public view returns (address) {
        return _manager;
    }
}