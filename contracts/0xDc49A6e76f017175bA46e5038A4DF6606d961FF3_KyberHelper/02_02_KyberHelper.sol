// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./interfaces/IKyber.sol";

contract KyberHelper {

    function getTicks(IKyber pool, uint maxTickNum) external view returns (bytes[] memory ticks) {
        (,,int24 tick,) = pool.getPoolState();

        int24[] memory initTicks = new int24[](maxTickNum);

        uint counter = 1;
        initTicks[0] = tick;

        (int24 previous, int24 next) = pool.initializedTicks(tick);
        if (previous != tick && previous != 0) {
            initTicks[counter] = previous;
            counter++;
        }
        if (next != tick && next != 0) {
            initTicks[counter] = next;
            counter++;
        }

        while ((next != 0 || previous != 0)) {
            if (previous != 0) {
                (int24 p, ) = pool.initializedTicks(previous);
                if (previous != p && p != 0) {
                    initTicks[counter] = p;
                    previous = p;
                    counter++;
                } else {
                    previous = 0;
                }
            }

            if (counter == maxTickNum) {
                break;
            }

            if (next != 0) {
                (, int24 n) = pool.initializedTicks(next);
                if (next != n && n != 0) {
                    initTicks[counter] = n;
                    next = n;
                    counter++;
                } else {
                    next = 0;
                }
            }

            if (counter == maxTickNum) {
                break;
            }
        }

        ticks = new bytes[](counter);
        for (uint i = 0; i < counter; i++) {
            (
                uint128 liquidityGross,
                int128 liquidityNet,
                ,
            ) = pool.ticks(initTicks[i]);

             ticks[i] = abi.encodePacked(
                 liquidityGross,
                 liquidityNet,
                 initTicks[i]
             );
        }
    }

}