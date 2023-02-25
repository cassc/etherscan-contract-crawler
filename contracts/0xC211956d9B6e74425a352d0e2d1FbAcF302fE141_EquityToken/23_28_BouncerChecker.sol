// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {AddressUint8FlagsLib} from "../bases/utils/AddressUint8FlagsLib.sol";

import {IBouncer} from "./interfaces/IBouncer.sol";

uint8 constant EMBEDDED_BOUNCER_FLAG_TYPE = 0x02;

enum EmbeddedBouncerType {
    DenyAll,
    AllowAll,
    AllowTransferToClassHolder,
    AllowTransferToAllHolders
}

abstract contract BouncerChecker {
    using AddressUint8FlagsLib for address;

    function numberOfClasses() public view virtual returns (uint256);
    function balanceOf(address account, uint256 classId) public view virtual returns (uint256);

    function bouncerAllowsTransfer(IBouncer bouncer, address from, address to, uint256 classId, uint256 amount)
        internal
        view
        returns (bool)
    {
        if (address(bouncer).isFlag(EMBEDDED_BOUNCER_FLAG_TYPE)) {
            EmbeddedBouncerType bouncerType = EmbeddedBouncerType(address(bouncer).flagValue());
            return embeddedBouncerAllowsTransfer(bouncerType, from, to, classId, amount);
        } else {
            return bouncer.isTransferAllowed(from, to, classId, amount);
        }
    }

    function embeddedBouncerAllowsTransfer(
        EmbeddedBouncerType bouncerType,
        address,
        address to,
        uint256 classId,
        uint256
    ) private view returns (bool) {
        if (bouncerType == EmbeddedBouncerType.AllowAll) {
            return true;
        } else if (bouncerType == EmbeddedBouncerType.DenyAll) {
            return false;
        } else if (bouncerType == EmbeddedBouncerType.AllowTransferToClassHolder) {
            return balanceOf(to, classId) > 0;
        } else if (bouncerType == EmbeddedBouncerType.AllowTransferToAllHolders) {
            uint256 count = numberOfClasses();
            for (uint256 i = 0; i < count;) {
                if (balanceOf(to, i) > 0) {
                    return true;
                }
                unchecked {
                    i++;
                }
            }
            return false;
        } else {
            return false;
        }
    }
}