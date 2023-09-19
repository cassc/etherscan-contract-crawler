// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/// @title Manageable
/// @notice Implements simple manager role that can be changed by a manger or external owner role
/// @dev This contract is designed to work with Ownable from openzeppelin
/// @custom:security-contact [email protected]
abstract contract Manageable {
    /// @notice wallet address of manager role
    address private _managerRole;

    /// @notice Emitted when manager is changed
    /// @param manager new manager address
    event ManagerChanged(address manager);

    error ManagerIsZero();
    error OnlyManager();
    error OnlyOwnerOrManager();
    error ManagerDidNotChange();

    modifier onlyManager() {
        if (_managerRole != msg.sender) revert OnlyManager();
        _;
    }

    /// @param _manager new manager address
    constructor(address _manager) {
        if (_manager == address(0)) revert ManagerIsZero();

        _managerRole = _manager;
    }

    /// @notice Change manager address
    /// @dev Callable by manager or external owner role
    /// @param _manager new manager address
    function changeManager(address _manager) external {
        if (msg.sender != owner() && msg.sender != _managerRole) {
            revert OnlyOwnerOrManager();
        }

        if (_manager == address(0)) revert ManagerIsZero();
        if (_manager == _managerRole) revert ManagerDidNotChange();

        _managerRole = _manager;
        emit ManagerChanged(_manager);
    }

    function manager() public view virtual returns (address) {
        return _managerRole;
    }

    /// @notice Gets external owner role
    /// @return owner address
    function owner() public view virtual returns (address);
}