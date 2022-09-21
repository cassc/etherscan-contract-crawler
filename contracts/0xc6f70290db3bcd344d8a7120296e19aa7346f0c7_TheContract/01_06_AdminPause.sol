// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AdminPrivileges.sol";

/**
* @notice THIS PRODUCT IS IN BETA, SIBLING LABS IS NOT RESPONSIBLE FOR ANY LOST FUNDS OR
* UNINTENDED CONSEQUENCES CAUSED BY THE USE OF THIS PRODUCT IN ANY FORM.
*/

/**
* @dev Contract which adds pausing functionality. Any function
* which uses the {whenNotPaused} modifier will revert when the
* contract is paused.
*
* Use {togglePause} to switch the paused state.
*
* Contract admins can run any function on a contract regardless
* of whether it is paused.
*
* See more module contracts from Sibling Labs at
* https://github.com/NFTSiblings/Modules
 */
contract AdminPause is AdminPrivileges {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool public paused;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused || isAdmin(msg.sender), "AdminPausable: contract is paused");
        _;
    }

    /**
    * @dev Toggle paused state.
    */
    function togglePause() public onlyAdmins {
        paused = !paused;
        if (paused) {
            emit Paused(msg.sender);
        } else {
            emit Unpaused(msg.sender);
        }
    }
}