// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;
import "./DragonInfo.sol";

library EggInfo {

    struct Details { 
        uint mintedAt;
        DragonInfo.Types dragonType;
        uint hatchedAt;
        uint dragonId;
    }

    function getDetails(uint value) internal pure returns (Details memory) {
        return Details (
            {
                mintedAt: uint256(uint64(value)),
                dragonType: DragonInfo.Types(uint16(value >> 64)),
                hatchedAt: uint256(uint64(value >> 80)),
                dragonId: uint256(uint32(value >> 144))
            }
        );
    }

    function getValue(Details memory details) internal pure returns (uint) {
        uint result = uint(details.mintedAt);
        result |= uint(details.dragonType) << 64;
        result |= uint(details.hatchedAt) << 80;
        result |= uint(details.dragonId) << 144;
        return result;
    }
}