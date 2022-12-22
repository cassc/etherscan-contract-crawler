// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Context.sol';
import './interfaces/IPausable.sol';

abstract contract Pausable is Context, IPausable {
    bool private _paused;

    modifier whenNotPaused() virtual {
        if (isPaused()) revert IsPaused();
        _;
    }

    modifier whenPaused() virtual {
        if (!isPaused()) revert IsNotPaused();
        _;
    }

    function isPaused() public view virtual override returns (bool) {
        return _paused;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;

        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;

        emit Unpaused(_msgSender());
    }
}