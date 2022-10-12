/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "./Facts.sol";

library FactSigs {
    /**
     * @notice Produce the fact signature for a birth certificate fact
     * @return A FactSignature with no verification fee
     */
    function birthCertificateFactSig() internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, abi.encode("BirthCertificate"));
    }

    /**
     * @notice Produce a fact signature for a storage slot
     * @param slot the account's slot
     * @param blockNum the block number to look at
     * @return A FactSignature with no verification fee
     */
    function storageSlotFactSig(bytes32 slot, uint256 blockNum)
        internal
        pure
        returns (FactSignature)
    {
        return Facts.toFactSignature(Facts.NO_FEE, abi.encode("StorageSlot", slot, blockNum));
    }

    /**
     * @notice Produce a fact signature for a given event
     * @param eventId The event in question
     * @return A FactSignature with no verification fee for the event
     */
    function eventFactSig(uint64 eventId) internal pure returns (FactSignature) {
        return
            Facts.toFactSignature(Facts.NO_FEE, abi.encode("EventAttendance", "EventID", eventId));
    }
}