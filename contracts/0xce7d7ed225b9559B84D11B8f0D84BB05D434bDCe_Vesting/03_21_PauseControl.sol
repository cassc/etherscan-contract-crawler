// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./ErrorCodes.sol";

abstract contract PauseControl {
    event OperationPaused(bytes32 op, address subject);
    event OperationUnpaused(bytes32 op, address subject);

    mapping(address => mapping(bytes32 => bool)) internal pausedOps;

    function validatePause(address subject) internal view virtual;

    function validateUnpause(address subject) internal view virtual;

    function isOperationPaused(bytes32 op, address subject) public view returns (bool) {
        return pausedOps[subject][op];
    }

    function pauseOperation(bytes32 op, address subject) external virtual {
        validatePause(subject);
        require(!isOperationPaused(op, subject));
        pausedOps[subject][op] = true;
        emit OperationPaused(op, subject);
    }

    function unpauseOperation(bytes32 op, address subject) external virtual {
        validateUnpause(subject);
        require(isOperationPaused(op, subject));
        pausedOps[subject][op] = false;
        emit OperationUnpaused(op, subject);
    }

    modifier checkPausedSubject(bytes32 op, address subject) {
        require(!isOperationPaused(op, subject), ErrorCodes.OPERATION_PAUSED);
        _;
    }

    modifier checkPaused(bytes32 op) {
        require(!isOperationPaused(op, address(0)), ErrorCodes.OPERATION_PAUSED);
        _;
    }
}