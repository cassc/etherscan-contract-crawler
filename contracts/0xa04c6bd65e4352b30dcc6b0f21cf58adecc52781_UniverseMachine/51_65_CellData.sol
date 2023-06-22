// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./SortedY.sol"; 
import "./Cell.sol";
import "./CellBlock.sol";

struct CellData {
    CellBlock cb;
    Cell[] cells;
    Cell current;
    uint32 used;
    SortedY[] sortedY;
    Cell[] sortedCells;
    bool sorted;
    Cell style;
    int32 minX;
    int32 maxX;
    int32 minY;
    int32 maxY;
}

library CellDataMethods {
    function create() internal pure returns (CellData memory cellData) {
        cellData.cb = CellBlockMethods.create(12);
        cellData.cells = new Cell[](cellData.cb.limit);
        cellData.sortedCells = new Cell[](0);
        cellData.sortedY = new SortedY[](0);
        cellData.sorted = false;
        cellData.style = CellMethods.create();
        cellData.current = CellMethods.create();
        cellData.minX = 0x7FFFFFFF;
        cellData.minY = 0x7FFFFFFF;
        cellData.maxX = -0x7FFFFFFF;
        cellData.maxY = -0x7FFFFFFF;
    }
}