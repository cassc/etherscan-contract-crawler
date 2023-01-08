// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IDeal {
    event RoomCreated(bytes32 roomId, address host, string metadata);
    event RoomJoined(bytes32 roomId, address counterparty);
    event RoomExited(bytes32 roomId, address party);
    event RoomClosed(bytes32 roomId);
    event OfferUpdated(bytes32 roomId, address party);
    event Swapped(bytes32 recordId);

    error ERoomExists(); // 0x4c88ca2a
    error ERoomDoesNotExist(); // 0x4b4e8872
    error ERoomNotJoined(); // 0x8890b3b1
    error ERoomAlreadyJoined(); // 0xc2d944a7
    error EOfferEmpty(); // 0x37416bb1
    error EOfferExpired(); // 0x8b87d9bd
    error EOfferInvalid(); // 0x67e71c08
    error EActionUnauthorized(); // 0x8c12a053
}