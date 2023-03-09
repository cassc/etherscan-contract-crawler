//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

import { PermissionAdmin } from "./PermissionAdmin.sol";

/**
 * @notice Base contract which allows children to implement an emergency stop
 * mechanism
 */

contract Pausable is PermissionAdmin {

    address internal _pauser;
    bool public paused;

    event Pause();
    event Unpause();
    event pauserChanged(address indexed newPauser);

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    /**
     * @dev throws if called by any account other than the pauser
     */
    modifier onlyPauser() {
        require(msg.sender == _pauser, "caller not pauser");
        _;
    }

    /**
     * @notice Returns current rescuer
     * @return Pauser's address
     */
    function getPauser() external view returns (address) {
        return _pauser;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() external onlyPauser {        
        require(paused == false, "already paused");
        paused = true;
        emit Pause();
    }

    function initPaused() public onlyInitializing {
        paused = false;
    }
    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() external onlyPauser {
        require(paused == true, "already unpaused");
        paused = false;
        emit Unpause();
    }

    /**
     * @dev update the pauser role
     */
    function updatePauser(address _newPauser) external onlyPermissionAdmin {
        //require(initialized, "Pausable: TokenV1 not initialized");
        require(
            _newPauser != address(0),
            "No zero addr"
        );
        _pauser = _newPauser;
        emit pauserChanged(_pauser);
    }
}