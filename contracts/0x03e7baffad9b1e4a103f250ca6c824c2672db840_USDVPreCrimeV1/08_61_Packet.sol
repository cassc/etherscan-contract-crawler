// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import {Origin} from "@layerzerolabs/lz-evm-protocol-v2/contracts/MessagingStructs.sol";
import {PacketV1Codec} from "@layerzerolabs/lz-evm-protocol-v2/contracts/messagelib/libs/PacketV1Codec.sol";

struct InboundPacket {
    Origin origin;
    uint32 dstEid;
    address receiver;
    bytes32 guid;
    bytes message;
}

library PacketDecoder {
    using PacketV1Codec for bytes;

    function decode(bytes calldata _packet) internal pure returns (InboundPacket memory packet) {
        packet.origin = Origin(_packet.srcEid(), _packet.sender(), _packet.nonce());
        packet.dstEid = _packet.dstEid();
        packet.receiver = _packet.receiverB20();
        packet.guid = _packet.guid();
        packet.message = _packet.message();
    }

    function decode(bytes[] calldata _packets) internal pure returns (InboundPacket[] memory packets) {
        packets = new InboundPacket[](_packets.length);
        for (uint i = 0; i < _packets.length; i++) {
            bytes calldata packet = _packets[i];
            packets[i] = PacketDecoder.decode(packet);
        }
    }
}