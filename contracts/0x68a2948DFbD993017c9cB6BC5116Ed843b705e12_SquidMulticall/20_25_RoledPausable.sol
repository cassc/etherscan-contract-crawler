// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IRoledPausable} from "./interfaces/IRoledPausable.sol";
import {StorageSlot} from "./libraries/StorageSlot.sol";

abstract contract RoledPausable is IRoledPausable {
    using StorageSlot for bytes32;

    bytes32 internal constant PAUSED_SLOT = keccak256("RoledPausable.paused");
    bytes32 internal constant PAUSER_SLOT = keccak256("RoledPausable.pauser");
    bytes32 internal constant PENDING_PAUSER_SLOT = keccak256("RoledPausable.pendingPauser");

    modifier whenNotPaused() {
        if (paused()) revert ContractIsPaused();
        _;
    }

    modifier onlyPauser() {
        if (msg.sender != pauser()) revert NotPauser();
        _;
    }

    constructor() {
        _setPauser(msg.sender);
    }

    function updatePauser(address newPauser) external onlyPauser {
        PENDING_PAUSER_SLOT.setAddress(newPauser);
        emit PauserProposed(msg.sender, newPauser);
    }

    function acceptPauser() external {
        if (msg.sender != pendingPauser()) revert NotPendingPauser();
        _setPauser(msg.sender);
        PENDING_PAUSER_SLOT.setAddress(address(0));
    }

    function pause() external virtual onlyPauser {
        PAUSED_SLOT.setBool(true);
        emit Paused();
    }

    function unpause() external virtual onlyPauser {
        PAUSED_SLOT.setBool(false);
        emit Unpaused();
    }

    function pauser() public view returns (address value) {
        value = PAUSER_SLOT.getAddress();
    }

    function paused() public view returns (bool value) {
        value = PAUSED_SLOT.getBool();
    }

    function pendingPauser() public view returns (address value) {
        value = PENDING_PAUSER_SLOT.getAddress();
    }

    function _setPauser(address _pauser) internal {
        PAUSER_SLOT.setAddress(_pauser);
        emit PauserUpdated(_pauser);
    }
}