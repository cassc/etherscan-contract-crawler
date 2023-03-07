/*
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.18;

import "../openzeppelin/utils/ContextUpgradeable.sol";

abstract contract Manageable is ContextUpgradeable {
    address private _manager;

    event ManagementTransferred(
        address indexed previousManager,
        address indexed newManager
    );

    function __Manageable_init() internal onlyInitializing {
        __Manageable_init_unchained();
    }

    function __Manageable_init_unchained() internal onlyInitializing {
        _manager = _msgSender();
        emit ManagementTransferred(address(0), _msgSender());
    }

    function _checkManager() private view {
        require(_manager == _msgSender(), "M: Caller not manager");
    }

    function manager() external view returns (address) {
        return _manager;
    }

    modifier onlyManager() {
        _checkManager();
        _;
    }

    /**
     * @notice Transfers the management of the contract to a new manager
     */
    function transferManagement(address newManager) external onlyManager {
        emit ManagementTransferred(_manager, newManager);
        _manager = newManager;
    }
}