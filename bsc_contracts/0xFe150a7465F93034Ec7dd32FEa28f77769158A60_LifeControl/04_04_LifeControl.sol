// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract LifeControl is Ownable, Pausable {
    event Terminated(address account);

    bool public terminated;

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _requireNotTerminated();
        _unpause();
    }

    function terminate() public onlyOwner whenPaused {
        _requireNotTerminated();
        terminated = true;
        emit Terminated(_msgSender());
    }

    function _requireNotTerminated() private view {
        require(!terminated, "LC: terminated");
    }
}