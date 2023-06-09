// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./StakingPoolV1Owned.sol";

abstract contract StakingPoolV1Pausable is StakingPoolV1Owned {
    bool public paused;
    uint256 public lastPauseTime;

    event PauseChanged(bool isPaused);

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused == paused) return;
        paused = _paused;
        if (paused) lastPauseTime = now;
        emit PauseChanged(paused);
    }

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}