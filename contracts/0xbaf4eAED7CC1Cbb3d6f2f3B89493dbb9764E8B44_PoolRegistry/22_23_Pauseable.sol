// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/IPauseable.sol";
import "../access/Governable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 */
abstract contract Pauseable is IPauseable, Governable {
    /// @notice Emitted when contract is turned on
    event Open(address caller);

    /// @notice Emitted when contract is paused
    event Paused(address caller);

    /// @notice Emitted when contract is shuted down
    event Shutdown(address caller);

    /// @notice Emitted when contract is unpaused
    event Unpaused(address caller);

    bool private _paused;
    bool private _everythingStopped;

    /**
     * @dev Throws if contract is paused
     */
    modifier whenNotPaused() {
        require(!paused(), "paused");
        _;
    }

    /**
     * @dev Throws if contract is shutdown
     */
    modifier whenNotShutdown() {
        require(!everythingStopped(), "shutdown");
        _;
    }

    /**
     * @dev Throws if contract is not paused
     */
    modifier whenPaused() {
        require(paused(), "not-paused");
        _;
    }

    /**
     * @dev Throws if contract is not shutdown
     */
    modifier whenShutdown() {
        require(everythingStopped(), "not-shutdown");
        _;
    }

    /**
     * @dev If inheriting child is using proxy then child contract can use
     * __Pauseable_init() function to initialization this contract
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Pauseable_init() internal initializer {
        __Governable_init();
    }

    /**
     * @notice Return `true` if contract is shutdown
     */
    function everythingStopped() public view virtual returns (bool) {
        return _everythingStopped;
    }

    /**
     * @notice Return `true` if contract is paused
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Open contract operations, if contract is in shutdown state
     */
    function open() external virtual whenShutdown onlyGovernor {
        _everythingStopped = false;
        emit Open(msg.sender);
    }

    /**
     * @dev Pause contract operations, if contract is not paused.
     */
    function pause() external virtual whenNotPaused onlyGovernor {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Shutdown contract operations, if not already shutdown.
     */
    function shutdown() external virtual whenNotShutdown onlyGovernor {
        _everythingStopped = true;
        _paused = true;
        emit Shutdown(msg.sender);
    }

    /**
     * @dev Unpause contract operations, allow only if contract is paused and not shutdown.
     */
    function unpause() external virtual whenPaused whenNotShutdown onlyGovernor {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}