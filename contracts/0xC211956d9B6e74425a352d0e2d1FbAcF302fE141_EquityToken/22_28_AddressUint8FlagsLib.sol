// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AddressUint8FlagsLib {
    // Address uint8 flag format: 0x00..00[flag uint8 byte][type of flag byte]

    // - The last byte of the address is used to signal the type of flag
    // - The second to last to store the specific uint8 being flagged
    // - All other bytes in the address must be 0
    uint256 internal constant ADDR_UINT8_FLAG_MASK = ~uint160(0xFF00);

    function isFlag(address addr, uint8 flagType) internal pure returns (bool) {
        // An address 0x00...00[roleId byte]01 is interpreted as a flag for flagType=0x01
        // Eg. In the case of roles, 0x0000000000000000000000000000000000000201 flags roleId=2
        // Therefore if any other byte other than the roleId byte or the 0x01 byte
        // is set, it will be considered not to be a valid role flag
        return (uint256(uint160(addr)) & ADDR_UINT8_FLAG_MASK) == uint256(flagType);
    }

    function flagValue(address addr) internal pure returns (uint8) {
        return uint8(uint160(addr) >> 8);
    }

    function toFlag(uint8 value, uint8 flagType) internal pure returns (address) {
        return address(uint160(uint256(value) << 8) + flagType);
    }
}