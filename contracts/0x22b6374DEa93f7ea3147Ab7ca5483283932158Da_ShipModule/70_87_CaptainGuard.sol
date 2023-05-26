// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import {ICaptainGuard} from "szns/interfaces/ICaptainGuard.sol";
import {ICaptainGuardEvents} from "szns/interfaces/ICaptainGuardEvents.sol";

/**
 * @title CaptainGuard
 * @dev This contract allows to guard a contract's functionality based on the address of the ship's captain
 */
contract CaptainGuard is ICaptainGuard, ICaptainGuardEvents {
    address public CAPTAIN;

    /**
     * @dev constructor to initialize the captain address
     * @param _captain The address of the ship's captain
     * @notice Revert if the _captain is a zero address.
     */
    constructor(address _captain) {
        // We don't check for ZERO address because
        // of proxy deployment
        CAPTAIN = _captain;
        emit CaptainAssigned(msg.sender, _captain);
    }

    /**
     * @dev This function allows to update the captain address.
     * @param _captain The new address of the ship's captain.
     * @notice Revert if the _captain is a zero address.
     */
    function updateCaptain(
        address _captain
    ) public virtual override onlyCaptain {
        if (_captain == address(0)) {
            revert ZeroAddressCaptain();
        }

        CAPTAIN = _captain;

        emit CaptainAssigned(msg.sender, _captain);
    }

    /**
     * @dev This function returns true if the msg.sender is the captain
     * @return true if msg.sender is the captain, false otherwise
     */
    function isCaptain() public view returns (bool) {
        return msg.sender == CAPTAIN;
    }

    /**
     * @dev This function allows to check if the msg.sender is the captain of the ship.
     * @notice Revert if the msg.sender is not the captain.
     */
    modifier onlyCaptain() {
        if (!isCaptain()) {
            revert NotCaptain();
        }
        _;
    }
}