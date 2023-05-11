// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

import { IPausable } from "./interfaces/IPausable.sol";
import { Initializable } from "./Initializable.sol";

/// @notice Modified from OpenZeppelin Contracts v4.7.3 (security/PausableUpgradeable.sol)
/// - Uses custom errors declared in IPausable
/// @notice repo github.com/ourzora/nouns-protocol
abstract contract Pausable is IPausable, Initializable {
    /// @dev If the contract is paused
    bool internal _paused;

    /// @dev Ensures the contract is paused
    modifier whenPaused() {
        if (!_paused) revert UNPAUSED();
        _;
    }

    /// @dev Ensures the contract isn't paused
    modifier whenNotPaused() {
        if (_paused) revert PAUSED();
        _;
    }

    /// @dev Sets whether the initial state
    /// @param _initPause If the contract should pause upon initialization
    function __Pausable_init(bool _initPause) internal onlyInitializing {
        _paused = _initPause;
    }

    /// @notice If the contract is paused
    function paused() external view returns (bool) {
        return _paused;
    }

    /// @dev Pauses the contract
    function _pause() internal virtual whenNotPaused {
        _paused = true;

        emit Paused(msg.sender);
    }

    /// @dev Unpauses the contract
    function _unpause() internal virtual whenPaused {
        _paused = false;

        emit Unpaused(msg.sender);
    }
}