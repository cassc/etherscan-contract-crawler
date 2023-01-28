// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PendingOwnable is Ownable {
    address private _pendingOwner;

    event SetPendingOwner(address indexed pendingOwner);

    constructor() Ownable() {}

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev This function is disabled to in place of setPendingOwner()
     */
    function transferOwnership(
        address /*newOwner*/
    ) public view override onlyOwner {
        revert("PendingOwnable: MUST setPendingOwner()");
    }

    /**
     * @dev Sets an account as the pending owner (`newPendingOwner`).
     * Can only be called by the current owner.
     */
    function setPendingOwner(address newPendingOwner) public virtual onlyOwner {
        _pendingOwner = newPendingOwner;
        emit SetPendingOwner(_pendingOwner);
    }

    /**
     * @dev Transfers ownership to the pending owner
     * Can only be called by the pending owner.
     */
    function acceptOwnership() public virtual {
        require(msg.sender == _pendingOwner, "PendingOwnable: MUST be pendingOwner");
        _pendingOwner = address(0);
        _transferOwnership(msg.sender);
    }
}