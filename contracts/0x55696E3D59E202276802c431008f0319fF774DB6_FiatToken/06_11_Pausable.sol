// SPDX-License-Identifier: MIT
// Forked from https://github.com/centrehq/centre-tokens/blob/master/contracts/v1/Pausable.sol

pragma solidity ^0.8.0;

import {Ownable} from "Ownable.sol";

/**
 * @notice Base contract which allows children to implement an emergency stop
 * mechanism
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();
    event PauserChanged(address indexed newAddress);

    address public pauser;
    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    /**
     * @dev throws if called by any account other than the pauser
     */
    modifier onlyPauser() {
        require(msg.sender == pauser, "Pausable: caller is not the pauser");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() external onlyPauser {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() external onlyPauser {
        paused = false;
        emit Unpause();
    }

    /**
     * @dev update the pauser role
     */
    function updatePauser(address _newPauser) external onlyOwner {
        require(
            _newPauser != address(0),
            "Pausable: new pauser is the zero address"
        );
        pauser = _newPauser;
        emit PauserChanged(pauser);
    }
}