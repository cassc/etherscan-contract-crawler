// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//Interface to control transfer of q2
interface ITransferController {
    /**
     * @dev Add `_user` status to `status` or Change `_user` status to `status`
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {AddOrChangeUserStatus} event.
     */

    function addOrChangeUserStatus(address _user, bool status)
        external
        returns (bool);

    /**
     * @dev Add `_moderator` status to `status` or Change `_moderator` status to `status`
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {ChangedModeratorStatus} event.
     */

    function addOrChangeModeratorStatus(address _moderator, bool status)
        external
        returns (bool);

    /**
     * @dev Returns status of user By default every address are false
     */

    function isWhiteListed(address _user) external view returns (bool);

    /**
     * @dev Emitted when the address status is added of a `user` or address status is changed of a `user`
     * is set by owner
     * a call to {addOrChangeUserStatus}. `status` is the new status.
     */
    event AddOrChangeUserStatus(address _address, bool status);

    /**
     * @dev Emitted when the address status is added of a `_moderator` or status is changed
     * of a `_moderator` is set by owner
     * a call to {addOrChangeModeratorStatus}. `status` is the new status.
     */
    event AddOrChangeModeratorStatus(address _moderator, bool status);
}