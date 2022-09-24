// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library CommonFunctions {
    /**
     *    y ▲
     *      │
     *      │
     * ymax │      ┌────────────────
     *      │      │
     *      │      │
     * ─────┼──────┴────────────────►
     *      │      x0               x
     **/
    function heaviside(uint256 x0, uint256 ymax, uint256 x) internal pure returns (uint256) {
        return x >= x0 ? ymax : 0;
    }

    /**
     *    y ▲
     *      │
     *      │
     * ymax │      ┌───────┐
     *      │      │       │
     *      │      │       │
     * ─────┼──────┴───────┴────────►
     *      │      x0      x1       x
     **/
    function rectangular(uint256 x0, uint256 x1, uint256 ymax, uint256 x) internal pure returns (uint256) {
        return heaviside(x0, ymax, x) - heaviside(x1, ymax, x);
    }

    /**
     *    y ▲             /
     *      │            /
     *      │           /
     *      │          /
     *      │         /
     *      │        /
     * ─────┼───────/───────────────►
     *      │      x0               x
     **/
    function slope(uint256 x0, uint256 x) internal pure returns (uint256) {
        return x >= x0 ? x - x0: 0;
    }

    /**
     *    y ▲
     *      │
     *      │
     * ymax │          ─────────────
     *      │         /
     *      │        /
     * ─────┼───────/───────────────►
     *      │      x0  x1           x
     **/
    function ramp(uint256 x0, uint256 x1, uint256 ymax, uint256 x) internal pure returns (uint256) {
        return ymax * (slope(x0, x) - slope(x1, x)) / (x1 - x0);
    }

    /**
     *    y ▲
     *      │
     *      │
     * ymax │          /\
     *      │         /  \
     *      │        /    \
     * ─────┼───────/──────\────────►
     *      │      x0 xmax x1       x
     **/
    function triangle(uint256 x0, uint256 xmax, uint256 x1, uint256 ymax, uint256 x) internal pure returns (uint256) {
        return ramp(x0, xmax, ymax, x) - ramp(xmax, x1, ymax, x);
    }

    /**
     *    y ▲                 ┌─────
     *      │     ←xstep→     │
     *      │           ┌─────┘
     *      │           │
     *      │     ┌─────┘
     *      │     │
     * ─────┼─────┴─────────────────►
     *      │                       x
     **/
    function step(uint256 xstep, uint256 x) internal pure returns (uint256) {
        return x / xstep * xstep;
    }

    /**
     *    y ▲
     *      │
     *      │  ←x1→  ←x1→  ←x1→
     * ymax │  ┌──┐  ┌──┐  ┌──┐  ┌─
     *      │  │  │  │  │  │  │  │
     *      │  │  │  │  │  │  │  │
     * ─────┼──┴──┴──┴──┴──┴──┴──┴──►
     *      │     ←x0→  ←x0→  ←x0→  x
     **/
    function slots(uint256 x0, uint256 x1, uint256 ymax, uint256 x) internal pure returns (uint256) {
        uint256 period = x0 + x1;
        return ymax * ((x + x1) / period - x / period);
    }
}