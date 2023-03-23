// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @dev DexDataFormat addPair = byte(dexID) + bytes3(feeRate) + bytes(arrayLength) + byte3[arrayLength](trasferFeeRate Lpool <-> openlev)
/// + byte3[arrayLength](transferFeeRate openLev -> Dex) + byte3[arrayLength](Dex -> transferFeeRate openLev)
/// exp: 0x0100000002011170000000011170000000011170000000
/// DexDataFormat dexdata = byte(dexID）+ bytes3(feeRate) + byte(arrayLength) + path
/// uniV2Path = bytes20[arraylength](address)
/// uniV3Path = bytes20(address)+ bytes20[arraylength-1](address + fee)
library DexData {
    // in byte
    uint constant DEX_INDEX = 0;
    uint constant FEE_INDEX = 1;
    uint constant ARRYLENTH_INDEX = 4;
    uint constant TRANSFERFEE_INDEX = 5;
    uint constant PATH_INDEX = 5;
    uint constant FEE_SIZE = 3;
    uint constant ADDRESS_SIZE = 20;
    uint constant NEXT_OFFSET = ADDRESS_SIZE + FEE_SIZE;

    uint8 constant DEX_UNIV2 = 1;
    uint8 constant DEX_UNIV3 = 2;
    uint8 constant DEX_PANCAKE = 3;
    uint8 constant DEX_SUSHI = 4;
    uint8 constant DEX_MDEX = 5;
    uint8 constant DEX_TRADERJOE = 6;
    uint8 constant DEX_SPOOKY = 7;
    uint8 constant DEX_QUICK = 8;
    uint8 constant DEX_SHIBA = 9;
    uint8 constant DEX_APE = 10;
    uint8 constant DEX_PANCAKEV1 = 11;
    uint8 constant DEX_BABY = 12;
    uint8 constant DEX_MOJITO = 13;
    uint8 constant DEX_KU = 14;
    uint8 constant DEX_BISWAP = 15;
    uint8 constant DEX_VVS = 20;

    function toDex(bytes memory data) internal pure returns (uint8) {
        require(data.length >= FEE_INDEX, "DexData: toDex wrong data format");
        uint8 temp;
        assembly {
            temp := byte(0, mload(add(data, add(0x20, DEX_INDEX))))
        }
        return temp;
    }

    function toFee(bytes memory data) internal pure returns (uint24) {
        require(data.length >= ARRYLENTH_INDEX, "DexData: toFee wrong data format");
        uint temp;
        assembly {
            temp := mload(add(data, add(0x20, FEE_INDEX)))
        }
        return uint24(temp >> (256 - (ARRYLENTH_INDEX - FEE_INDEX) * 8));
    }

    function toDexDetail(bytes memory data) internal pure returns (uint32) {
        require(data.length >= FEE_INDEX, "DexData: toDexDetail wrong data format");
        if (isUniV2Class(data)) {
            uint8 temp;
            assembly {
                temp := byte(0, mload(add(data, add(0x20, DEX_INDEX))))
            }
            return uint32(temp);
        } else {
            uint temp;
            assembly {
                temp := mload(add(data, add(0x20, DEX_INDEX)))
            }
            return uint32(temp >> (256 - ((FEE_SIZE + FEE_INDEX) * 8)));
        }
    }

    function isUniV2Class(bytes memory data) internal pure returns (bool) {
        return toDex(data) != DEX_UNIV3;
    }

    function subByte(bytes memory data, uint startIndex, uint len) internal pure returns (bytes memory bts) {
        require(startIndex <= data.length && data.length - startIndex >= len, "DexData: wrong data format");
        uint addr;
        assembly {
            addr := add(data, 32)
        }
        addr = addr + startIndex;
        bts = new bytes(len);
        uint btsptr;
        assembly {
            btsptr := add(bts, 32)
        }
        for (; len > 32; len -= 32) {
            assembly {
                mstore(btsptr, mload(addr))
            }
            btsptr += 32;
            addr += 32;
        }
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(addr), not(mask))
            let destpart := and(mload(btsptr), mask)
            mstore(btsptr, or(destpart, srcpart))
        }
    }

    function bytesToAddress(bytes memory bys) internal pure returns (address addr) {
        require(bys.length == 32, "length error");
        assembly {
            addr := mload(add(bys, 32))
        }
    }

    function toBytes(uint _num) internal pure returns (bytes memory _ret) {
        assembly {
            _ret := mload(0x10)
            mstore(_ret, 0x20)
            mstore(add(_ret, 0x20), _num)
        }
    }

    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;
        assembly {
            tempBytes := mload(0x40)
            let length := mload(_preBytes)
            mstore(tempBytes, length)
            let mc := add(tempBytes, 0x20)
            let end := add(mc, length)
            for {
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))
            mc := end
            end := add(mc, length)
            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }
            mstore(0x40, and(add(add(end, iszero(add(length, mload(_preBytes)))), 31), not(31)))
        }
        return tempBytes;
    }
}