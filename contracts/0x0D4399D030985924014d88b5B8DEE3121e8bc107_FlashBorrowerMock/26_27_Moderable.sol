// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import '@openzeppelin/contracts/utils/Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an moderator) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the moderator account will be the one that deploys the contract. This
 * can later be changed with {transferModeratorship}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyModerator`, which can be applied to your functions to restrict their use to
 * the moderator.
 */
abstract contract Moderable is Context {
    address private _moderator;

    event ModeratorTransferred(address indexed previousModerator, address indexed newModerator);

    /**
     * @dev Initializes the contract setting the deployer as the initial moderator.
     */
    constructor() {
        address msgSender = _msgSender();
        _moderator = msgSender;
        emit ModeratorTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current moderator.
     */
    function moderator() public view virtual returns (address) {
        return _moderator;
    }

    /**
     * @dev Throws if called by any account other than the moderator.
     */
    modifier onlyModerator() {
        require(moderator() == _msgSender(), 'Moderator: caller is not the moderator');
        _;
    }

    /**
     * @dev Leaves the contract without moderator. It will not be possible to call
     * `onlyModerator` functions anymore. Can only be called by the current moderator.
     *
     * NOTE: Renouncing moderatorship will leave the contract without an moderator,
     * thereby removing any functionality that is only available to the moderator.
     */
    function renounceModeratorship() public virtual onlyModerator {
        emit ModeratorTransferred(_moderator, address(0));
        _moderator = address(0);
    }

    /**
     * @dev Transfers moderatorship of the contract to a new account (`newModeratorship`).
     * Can only be called by the current moderator.
     */
    function transferModeratorship(address newModerator) public virtual onlyModerator {
        require(newModerator != address(0), 'Moderable: new moderator is the zero address');
        emit ModeratorTransferred(_moderator, newModerator);
        _moderator = newModerator;
    }
}