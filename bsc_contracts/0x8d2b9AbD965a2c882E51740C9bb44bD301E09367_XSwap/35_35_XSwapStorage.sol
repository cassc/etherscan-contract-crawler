// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {StorageSlot} from "./lib/StorageSlot.sol";

import {ILifeControl} from "./core/life/ILifeControl.sol";

abstract contract XSwapStorage {
    // bytes32 internal constant INITIALIZER_SLOT = bytes32(uint256(keccak256("xSwap.v2.XSwap._initializer")) - 1);
    bytes32 internal constant INITIALIZER_SLOT = 0x3623293b0ffb92d90ed57651d3642673495a0188d7e022c09c543c9969626c44;

    // prettier-ignore
    // bytes32 internal constant WITHDRAW_WHITELIST_SLOT = bytes32(uint256(keccak256("xSwap.v2.XSwap._withdrawWhitelist")) - 1);
    bytes32 internal constant WITHDRAW_WHITELIST_SLOT = 0x4bd3e4129f347789784c66e779a32160b856695506e147fcaa130ce576c4cb1b;

    // bytes32 internal constant _LIFE_CONTROL_SLOT = bytes32(uint256(keccak256("xSwap.v2.XSwap._lifeControl")) - 1);
    bytes32 private constant _LIFE_CONTROL_SLOT = 0x871cbad836638a5df48f5f4cd4da62b7497b7b8a763c0aa30ded7ca399e95121;

    function _lifeControlStorage() private pure returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_LIFE_CONTROL_SLOT);
    }

    function _lifeControl() internal view returns (ILifeControl) {
        return ILifeControl(_lifeControlStorage().value);
    }

    function _setLifeControl(address lifeControl_) internal {
        _lifeControlStorage().value = lifeControl_;
    }
}