// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./CellData.sol";
import "./SubpixelScale.sol";
import "./Graphics2D.sol";

library CellRasterizer {
    function resetCells(CellData memory cellData)
        internal
        pure
    {
        cellData.used = 0;
        cellData.style = CellMethods.create();
        cellData.current = CellMethods.create();
        cellData.sorted = false;

        cellData.minX = 0x7FFFFFFF;
        cellData.minY = 0x7FFFFFFF;
        cellData.maxX = -0x7FFFFFFF;
        cellData.maxY = -0x7FFFFFFF;
    }

    struct Line {
        int32 x1;
        int32 y1;
        int32 x2;
        int32 y2;
    }

    struct LineArgs {
        int32 dx;
        int32 dy;
        int32 ex1;
        int32 ex2;
        int32 ey1;
        int32 ey2;
        int32 fy1;
        int32 fy2;
        int32 delta;
        int32 first;
        int32 incr;
    }

    function line(Line memory f, CellData memory cellData, SubpixelScale memory ss) internal pure {
        LineArgs memory a;

        a.dx = f.x2 - f.x1;

        if (a.dx >= int32(ss.dxLimit) || a.dx <= -int32(ss.dxLimit)) {
            int32 cx = (f.x1 + f.x2) >> 1;
            int32 cy = (f.y1 + f.y2) >> 1;
            line(Line(f.x1, f.y1, cx, cy), cellData, ss);
            line(Line(cx, cy, f.x2, f.y2), cellData, ss);
        }

        a.dy = f.y2 - f.y1;
        a.ex1 = f.x1 >> ss.value;
        a.ex2 = f.x2 >> ss.value;
        a.ey1 = f.y1 >> ss.value;
        a.ey2 = f.y2 >> ss.value;
        a.fy1 = f.y1 & int32(ss.mask);
        a.fy2 = f.y2 & int32(ss.mask);

        {
            if (a.ex1 < cellData.minX) cellData.minX = a.ex1;
            if (a.ex1 > cellData.maxX) cellData.maxX = a.ex1;
            if (a.ey1 < cellData.minY) cellData.minY = a.ey1;
            if (a.ey1 > cellData.maxY) cellData.maxY = a.ey1;
            if (a.ex2 < cellData.minX) cellData.minX = a.ex2;
            if (a.ex2 > cellData.maxX) cellData.maxX = a.ex2;
            if (a.ey2 < cellData.minY) cellData.minY = a.ey2;
            if (a.ey2 > cellData.maxY) cellData.maxY = a.ey2;

            setCurrentCell(a.ex1, a.ey1, cellData);

            if (a.ey1 == a.ey2) {
                renderHorizontalLine(                    
                    RenderHorizontalLine(a.ey1, f.x1, a.fy1, f.x2, a.fy2),
                    cellData, ss
                );
                return;
            }
        }

        a.incr = 1;

        if (a.dx == 0) {
            int32 ex = f.x1 >> ss.value;
            int32 twoFx = (f.x1 - (ex << ss.value)) << 1;

            a.first = int32(ss.scale);
            if (a.dy < 0) {
                a.first = 0;
                a.incr = -1;
            }

            a.delta = a.first - a.fy1;
            cellData.current.cover += a.delta;
            cellData.current.area += twoFx * a.delta;

            a.ey1 += a.incr;
            setCurrentCell(ex, a.ey1, cellData);

            a.delta = a.first + a.first - int32(ss.scale);
            int32 area = twoFx * a.delta;
            while (a.ey1 != a.ey2) {
                cellData.current.cover = a.delta;
                cellData.current.area = area;
                a.ey1 += a.incr;
                setCurrentCell(ex, a.ey1, cellData);
            }

            a.delta = a.fy2 - int32(ss.scale) + a.first;
            cellData.current.cover += a.delta;
            cellData.current.area += twoFx * a.delta;
            return;
        }

        int32 p = (int32(ss.scale) - a.fy1) * a.dx;
        a.first = int32(ss.scale);

        if (a.dy < 0) {
            p = a.fy1 * a.dx;
            a.first = 0;
            a.incr = -1;
            a.dy = -a.dy;
        }

        a.delta = p / a.dy;
        int32 mod = p % a.dy;

        if (mod < 0) {
            a.delta--;
            mod += a.dy;
        }

        int32 xFrom = f.x1 + a.delta;
        renderHorizontalLine(            
            RenderHorizontalLine(a.ey1, f.x1, a.fy1, xFrom, a.first), cellData, ss
        );

        a.ey1 += a.incr;
        setCurrentCell(xFrom >> ss.value, a.ey1, cellData);

        if (a.ey1 != a.ey2) {
            p = int32(ss.scale) * a.dx;
            int32 lift = p / a.dy;
            int32 rem = p % a.dy;

            if (rem < 0) {
                lift--;
                rem += a.dy;
            }

            mod -= a.dy;

            while (a.ey1 != a.ey2) {
                a.delta = lift;
                mod += rem;
                if (mod >= 0) {
                    mod -= a.dy;
                    a.delta++;
                }

                int32 xTo = xFrom + a.delta;
                renderHorizontalLine(
                    RenderHorizontalLine(
                        a.ey1,
                        xFrom,
                        int32(ss.scale) - a.first,
                        xTo,
                        a.first
                    ), cellData, ss
                );
                xFrom = xTo;

                a.ey1 += a.incr;
                setCurrentCell(xFrom >> ss.value, a.ey1, cellData);
            }
        }

        renderHorizontalLine(            
            RenderHorizontalLine(
                a.ey1,
                xFrom,
                int32(ss.scale) - a.first,
                f.x2,
                a.fy2
            ), cellData, ss
        );
    }

    function sortCells(CellData memory cellData) internal pure {
        if (cellData.sorted) return;

        addCurrentCell(cellData);
        cellData.current.x = 0x7FFFFFFF;
        cellData.current.y = 0x7FFFFFFF;
        cellData.current.cover = 0;
        cellData.current.area = 0;

        if (cellData.used == 0) return;

        cellData.sortedCells = new Cell[](cellData.used);
        cellData.sortedY = new SortedY[](
            uint32(cellData.maxY - cellData.minY + 1)
        );

        Cell[] memory cells = cellData.cells;
        SortedY[] memory sortedYData = cellData.sortedY;
        Cell[] memory sortedCellsData = cellData.sortedCells;

        for (uint32 i = 0; i < cellData.used; i++) {
            int32 index = cells[i].y - cellData.minY;
            sortedYData[uint32(index)].start++;
        }

        int32 start = 0;
        uint32 sortedYSize = uint32(cellData.sortedY.length);
        for (uint32 i = 0; i < sortedYSize; i++) {
            int32 v = sortedYData[i].start;
            sortedYData[i].start = start;
            start += v;
        }

        for (uint32 i = 0; i < cellData.used; i++) {
            int32 index = cells[i].y - cellData.minY;
            int32 currentYStart = sortedYData[uint32(index)].start;
            int32 currentYCount = sortedYData[uint32(index)].count;
            sortedCellsData[uint32(currentYStart + currentYCount)] = cells[i];
            ++sortedYData[uint32(index)].count;
        }

        for (uint32 i = 0; i < sortedYSize; i++)
            if (sortedYData[i].count != 0)
                sort(
                    sortedCellsData,
                    sortedYData[i].start,
                    sortedYData[i].start + sortedYData[i].count - 1
                );

        cellData.sorted = true;
    }

    struct RenderHorizontalLine {
        int32 ey;
        int32 x1;
        int32 y1;
        int32 x2;
        int32 y2;
    }

    struct RenderHorizontalLineArgs {
        int32 ex1;
        int32 ex2;
        int32 fx1;
        int32 fx2;
        int32 delta;
    }

    function renderHorizontalLine(        
        RenderHorizontalLine memory f,
        CellData memory cellData,
        SubpixelScale memory ss
    ) private pure {
        RenderHorizontalLineArgs memory a;

        a.ex1 = f.x1 >> ss.value;
        a.ex2 = f.x2 >> ss.value;
        a.fx1 = f.x1 & int32(ss.mask);
        a.fx2 = f.x2 & int32(ss.mask);
        a.delta = 0;

        if (f.y1 == f.y2) {
            setCurrentCell(a.ex2, f.ey, cellData);
            return;
        }

        if (a.ex1 == a.ex2) {
            a.delta = f.y2 - f.y1;
            cellData.current.cover += a.delta;
            cellData.current.area += (a.fx1 + a.fx2) * a.delta;
            return;
        }

        int32 p = (int32(ss.scale) - a.fx1) * (f.y2 - f.y1);
        int32 first = int32(ss.scale);
        int32 incr = 1;
        int32 dx = f.x2 - f.x1;

        if (dx < 0) {
            p = a.fx1 * (f.y2 - f.y1);
            first = 0;
            incr = -1;
            dx = -dx;
        }

        a.delta = p / dx;
        int32 mod = p % dx;

        if (mod < 0) {
            a.delta--;
            mod += dx;
        }

        cellData.current.cover += a.delta;
        cellData.current.area += (a.fx1 + first) * a.delta;

        a.ex1 += incr;
        setCurrentCell(a.ex1, f.ey, cellData);
        f.y1 += a.delta;

        if (a.ex1 != a.ex2) {
            p = int32(ss.scale) * (f.y2 - f.y1 + a.delta);
            int32 lift = p / dx;
            int32 rem = p % dx;

            if (rem < 0) {
                lift--;
                rem += dx;
            }

            mod -= dx;

            while (a.ex1 != a.ex2) {
                a.delta = lift;
                mod += rem;
                if (mod >= 0) {
                    mod -= dx;
                    a.delta++;
                }

                cellData.current.cover += a.delta;
                cellData.current.area += int32(ss.scale) * a.delta;
                f.y1 += a.delta;
                a.ex1 += incr;
                setCurrentCell(a.ex1, f.ey, cellData);
            }
        }

        a.delta = f.y2 - f.y1;
        cellData.current.cover += a.delta;
        cellData.current.area +=
            (a.fx2 + int32(ss.scale) - first) *
            a.delta;
    }

    function setCurrentCell(
        int32 x,
        int32 y,
        CellData memory cellData
    ) private pure {
        if (CellMethods.notEqual(cellData.current, x, y, cellData.style)) {
            addCurrentCell(cellData);
            CellMethods.style(cellData.current, cellData.style);
            cellData.current.x = x;
            cellData.current.y = y;
            cellData.current.cover = 0;
            cellData.current.area = 0;
        }
    }

    function addCurrentCell(CellData memory cellData) private pure {
        if ((cellData.current.area | cellData.current.cover) != 0) {
            if (cellData.used >= cellData.cb.limit) return;
            CellMethods.set(cellData.cells[cellData.used], cellData.current);
            cellData.used++;
        }
    }

    function sort(
        Cell[] memory cells,
        int32 start,
        int32 stop
    ) private pure {
        while (true) {
            if (stop == start) return;

            int32 pivot = getPivotPoint(cells, start, stop);
            if (pivot > start) sort(cells, start, pivot - 1);

            if (pivot < stop) {
                start = pivot + 1;
                continue;
            }

            break;
        }
    }

    function getPivotPoint(
        Cell[] memory cells,
        int32 start,
        int32 stop
    ) private pure returns (int32) {
        int32 m = start + 1;
        int32 n = stop;
        while (m < stop && cells[uint32(start)].x >= cells[uint32(m)].x) m++;

        while (n > start && cells[uint32(start)].x <= cells[uint32(n)].x) n--;
        while (m < n) {
            (cells[uint32(m)], cells[uint32(n)]) = (
                cells[uint32(n)],
                cells[uint32(m)]
            );
            while (m < stop && cells[uint32(start)].x >= cells[uint32(m)].x)
                m++;
            while (n > start && cells[uint32(start)].x <= cells[uint32(n)].x)
                n--;
        }

        if (start != n) {
            (cells[uint32(n)], cells[uint32(start)]) = (
                cells[uint32(start)],
                cells[uint32(n)]
            );
        }

        return n;
    }
}