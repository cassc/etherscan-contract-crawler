// SPDX-License-Identifier: AGPL-3.0
// ©2023 Ponderware Ltd

pragma solidity ^0.8.17;

import "solmate/src/utils/SSTORE2.sol";

library ItemStorage {

    struct Block {
        uint48 total;
        uint48 count;
        address pointer;
    }

    struct Store {
        Block[] blocks;
    }

    function total (Store storage store) internal view returns (uint48) {
        uint len = store.blocks.length;
        if (len == 0) {
            return 0;
        } else {
            return store.blocks[len - 1].total;
        }
    }

    function upload (Store storage store, uint48 count, bytes memory data) internal {
        require(data.length < 65536, "Too large");
        address pointer = SSTORE2.write(data);
        store.blocks.push(Block(uint48(total(store) + count), count, pointer));
    }

    function sideload (Store storage store, uint48 count, address pointer) internal {
        store.blocks.push(Block(uint48(total(store)) + count, count, pointer));
    }

    function bget (Store storage store, uint id) internal view returns (bytes memory) {
        require(id < total(store), "Out of bounds");
        uint last = store.blocks.length - 1;
        uint cursor = last / 2;
        Block storage b = store.blocks[cursor];
        while (true) {
            if (id >= b.total) {
                cursor = (last - cursor + 1) / 2 + cursor;
            } else if (id < (b.total - b.count)) {
                uint temp = cursor;
                last = cursor;
                cursor = temp / 2;
            } else {
                cursor = b.count - (b.total - id);
                break;
            }
            b = store.blocks[cursor];
        }
        address pointer = b.pointer;
        uint pos = cursor * 2;
        uint dataStart = uint16(bytes2(SSTORE2.read(pointer, pos, pos + 2)));
        uint dataEnd = uint16(bytes2(SSTORE2.read(pointer, pos + 2, pos + 4)));
        return SSTORE2.read(pointer, dataStart, dataEnd);
    }

    function lget (Store storage store, uint id) internal view returns (bytes memory) {
        require(id < total(store), "Out of bounds");
        uint cursor = 0;
        Block storage b = store.blocks[cursor];
        while (true) {
            if (id < b.total) {
                cursor = b.count - (b.total - id);
                break;
            }
            b = store.blocks[++cursor];
        }
        address pointer = b.pointer;
        uint pos = cursor * 2;
        uint dataStart = uint16(bytes2(SSTORE2.read(pointer, pos, pos + 2)));
        uint dataEnd = uint16(bytes2(SSTORE2.read(pointer, pos + 2, pos + 4)));
        return SSTORE2.read(pointer, dataStart, dataEnd);
    }

}