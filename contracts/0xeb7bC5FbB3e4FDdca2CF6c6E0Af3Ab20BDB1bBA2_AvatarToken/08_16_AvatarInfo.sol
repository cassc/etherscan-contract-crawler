// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library AvatarInfo {

    struct Details { 
        uint mintedAt;
        uint grownAt;
    }

    function getDetails(uint value) internal pure returns (Details memory) {
        return Details (
            {
                mintedAt: uint256(uint128(value)),
                grownAt: uint256(uint128(value >> 128))
            }
        );
    }

    function getValue(Details memory details) internal pure returns (uint) {
        uint result = uint(details.mintedAt);
        result |= uint(details.grownAt) << 128;
        return result;
    }
}