// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

struct Cell {
    int32 x;
    int32 y;
    int32 cover;
    int32 area;
    int32 left;
    int32 right;
}

library CellMethods {
    function create() internal pure returns (Cell memory cell) {
        cell.x = 0x7FFFFFFF;
        cell.y = 0x7FFFFFFF;
        cell.cover = 0;
        cell.area = 0;
        cell.left = -1;
        cell.right = -1;
    }

    function set(Cell memory cell, Cell memory other) internal pure {
        cell.x = other.x;
        cell.y = other.y;
        cell.cover = other.cover;
        cell.area = other.area;
        cell.left = other.left;
        cell.right = other.right;
    }

    function style(Cell memory self, Cell memory other) internal pure {
        self.left = other.left;
        self.right = other.right;
    }

    function notEqual(
        Cell memory self,
        int32 ex,
        int32 ey,
        Cell memory other
    ) internal pure returns (bool) {
        unchecked {
            return
                ((ex - self.x) |
                    (ey - self.y) |
                    (self.left - other.left) |
                    (self.right - other.right)) != 0;
        }
    }
}