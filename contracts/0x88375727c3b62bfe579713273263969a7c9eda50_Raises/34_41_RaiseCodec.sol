// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {RaiseData, TierType} from "../../structs/RaiseData.sol";
import {ONE_BYTE, ONE_BYTE_MASK, FOUR_BYTES, FOUR_BYTE_MASK} from "../../constants/Codecs.sol";

// |-------- Raise token data is encoded in 30 bytes -----------|
// 0x000000000000000000000000000000000000000000000000000000000000
// 4 byte project ID                                     pppppppp
// 4 byte raise ID                               rrrrrrrr
// 4 byte tier ID                        tttttttt
// 1 byte tier type                    TT
//   ----------------------------------  17 empty bytes reserved

uint240 constant PROJECT_ID_SIZE = uint240(FOUR_BYTES);
uint240 constant RAISE_ID_SIZE = uint240(FOUR_BYTES);
uint240 constant TIER_ID_SIZE = uint240(FOUR_BYTES);
uint240 constant TIER_TYPE_SIZE = uint240(ONE_BYTE);

uint240 constant RAISE_ID_OFFSET = PROJECT_ID_SIZE;
uint240 constant TIER_ID_OFFSET = RAISE_ID_OFFSET + RAISE_ID_SIZE;
uint240 constant TIER_TYPE_OFFSET = TIER_ID_OFFSET + TIER_ID_SIZE;

uint240 constant PROJECT_ID_MASK = uint240(FOUR_BYTE_MASK);
uint240 constant RAISE_ID_MASK = uint240(FOUR_BYTE_MASK) << RAISE_ID_OFFSET;
uint240 constant TIER_ID_MASK = uint240(FOUR_BYTE_MASK) << TIER_ID_OFFSET;
uint240 constant TIER_TYPE_MASK = uint240(ONE_BYTE_MASK) << TIER_TYPE_OFFSET;

bytes17 constant RESERVED_REGION = 0x0;

/// @title RaiseCodec - Raise token encoder/decoder
/// @notice Converts between token data bytes and RaiseData struct.
library RaiseCodec {
    function encode(RaiseData memory raise) internal pure returns (bytes30) {
        bytes memory encoded =
            abi.encodePacked(RESERVED_REGION, raise.tierType, raise.tierId, raise.raiseId, raise.projectId);
        return bytes30(encoded);
    }

    function decode(bytes30 tokenData) internal pure returns (RaiseData memory) {
        uint240 bits = uint240(tokenData);

        uint32 projectId = uint32(bits & PROJECT_ID_MASK);
        uint32 raiseId = uint32((bits & RAISE_ID_MASK) >> RAISE_ID_OFFSET);
        uint32 tierId = uint32((bits & TIER_ID_MASK) >> TIER_ID_OFFSET);
        TierType tierType = TierType((bits & TIER_TYPE_MASK) >> TIER_TYPE_OFFSET);

        return RaiseData({tierType: tierType, tierId: tierId, raiseId: raiseId, projectId: projectId});
    }
}