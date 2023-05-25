// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { Pausable as PausableBase } from '@openzeppelin/contracts/security/Pausable.sol';
import { ManagerRole } from './roles/ManagerRole.sol';

/**
 * @title Pausable
 * @notice Base contract that implements the emergency pause mechanism
 */
abstract contract Pausable is PausableBase, ManagerRole {
    /**
     * @notice Enter pause state
     */
    function pause() external onlyManager whenNotPaused {
        _pause();
    }

    /**
     * @notice Exit pause state
     */
    function unpause() external onlyManager whenPaused {
        _unpause();
    }
}