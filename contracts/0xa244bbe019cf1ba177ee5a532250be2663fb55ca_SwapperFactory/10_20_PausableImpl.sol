// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {OwnableImpl} from "./OwnableImpl.sol";

/// @title Pausable Implementation
/// @author 0xSplits
/// @notice Pausable clone-implementation
abstract contract PausableImpl is OwnableImpl {
    error Paused();

    event SetPaused(bool paused);

    /// -----------------------------------------------------------------------
    /// storage - mutables
    /// -----------------------------------------------------------------------

    /// slot 0 - 11 bytes free

    /// OwnableImpl storage
    /// address internal $owner;
    /// 20 bytes

    bool internal $paused;
    /// 1 byte

    /// -----------------------------------------------------------------------
    /// constructor & initializer
    /// -----------------------------------------------------------------------

    constructor() {}

    function __initPausable(address owner_, bool paused_) internal virtual {
        OwnableImpl.__initOwnable(owner_);
        $paused = paused_;
    }

    /// -----------------------------------------------------------------------
    /// modifiers
    /// -----------------------------------------------------------------------

    modifier pausable() virtual {
        if (paused()) revert Paused();
        _;
    }

    /// -----------------------------------------------------------------------
    /// functions - public & external - onlyOwner
    /// -----------------------------------------------------------------------

    function setPaused(bool paused_) public virtual onlyOwner {
        $paused = paused_;
        emit SetPaused(paused_);
    }

    /// -----------------------------------------------------------------------
    /// functions - public & external - view
    /// -----------------------------------------------------------------------

    function paused() public view virtual returns (bool) {
        return $paused;
    }
}