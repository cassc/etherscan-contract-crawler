// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Pausable} from "../../lib/Pausable.sol";
import {Ownable} from "../../lib/Ownable.sol";

import {ILifeControl} from "./ILifeControl.sol";

/**
 * @dev See {ILifeControl}.
 */
contract LifeControl is ILifeControl, Ownable, Pausable {
    bool private _terminated;

    /**
     * @dev See {ILifeControl-pause}.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev See {ILifeControl-unpause}.
     */
    function unpause() public onlyOwner {
        _requireNotTerminated();
        _unpause();
    }

    /**
     * @dev See {ILifeControl-terminate}.
     */
    function terminate() public onlyOwner whenPaused {
        _requireNotTerminated();
        _terminated = true;
        emit Terminated(_msgSender());
    }

    /**
     * @dev See {ILifeControl-terminated}.
     */
    function terminated() public view returns (bool) {
        return _terminated;
    }

    /**
     * @dev Throws if contract is in the terminated state.
     */
    function _requireNotTerminated() private view {
        require(!_terminated, "LC: terminated");
    }
}