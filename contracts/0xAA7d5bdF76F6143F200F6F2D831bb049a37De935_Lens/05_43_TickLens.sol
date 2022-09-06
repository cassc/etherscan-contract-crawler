// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

import "../../interfaces/lens/ITickLens.sol";
import "../../libraries/Ticks.sol";
import "./LensBase.sol";

abstract contract TickLens is ITickLens, LensBase {
    using Bytes32ArrayLib for Bytes32ArrayLib.Bytes32Array;

    /// @inheritdoc ITickLens
    function getTicks(
        bytes32 poolId,
        uint8 tierId,
        int24 tickStart,
        int24 tickEnd,
        uint24 maxCount
    ) external view returns (uint256 count, bytes memory ticks) {
        bool upwardDirection = tickEnd - tickStart >= 0;
        int24 tickIdx = tickStart;
        Bytes32ArrayLib.Bytes32Array memory arr;

        bytes32 tierTicksSlot = _getTierTicksSlot(poolId, tierId);

        while (arr.length < maxCount) {
            uint256 data = uint256(hub.getStorageAt(_getTickSlot(tierTicksSlot, tickIdx)));

            uint192 liquidityLowerAndUpperD8 = uint192(data & 0xffffffffffffffffffffffffffffffff); // (1 << 128) - 1)
            int24 nextBelow = int24(int256(data >> 192) & 0xffffff); // (1 << 24) - 1)
            int24 nextAbove = int24(int256(data >> 216) & 0xffffff); // (1 << 24) - 1)
            uint16 needSettle0And1 = uint16((data >> 240) & 0xffff); // (1 << 16) - 1)

            // for the first tick, check if it is initialized
            if (arr.length == 0 && liquidityLowerAndUpperD8 == 0) break;

            arr.push(bytes32(abi.encodePacked(
                tickIdx, //                     int24
                liquidityLowerAndUpperD8, //    uint96 + uint96
                needSettle0And1 //              bool + bool
            ))); // prettier-ignore

            int24 tickNext = upwardDirection ? int24(nextAbove) : int24(nextBelow);

            if (tickIdx == tickNext) break; // it only happens when it reaches end tick
            if (upwardDirection ? tickNext > tickEnd : tickNext < tickEnd) break;
            tickIdx = tickNext;
        }

        arr.end();
        ticks = arr.data;
        count = arr.length;
    }

    /// @dev Returns the slot of `pools[poolId].ticks[tierId]`, i.e. `mapping(uint256 => mapping(int24 => Ticks.Tick)))`
    function _getTierTicksSlot(bytes32 poolId, uint8 tierId) internal pure returns (bytes32 tierTicksSlot) {
        bytes32 poolSlot = keccak256(abi.encodePacked(poolId, uint256(4))); // slot 4 in hub contract
        bytes32 ticksSlot = bytes32(uint256(poolSlot) + 3); // offset 3 in pool struct
        tierTicksSlot = keccak256(abi.encodePacked(uint256(tierId), ticksSlot));
    }

    /// @dev Returns the slot of `pools[poolId].ticks[tierId][tickIdx]`, i.e. the first slot of a `Ticks.Tick`
    function _getTickSlot(bytes32 tierTicksSlot, int24 tickIdx) internal pure returns (bytes32 tickSlot) {
        // note that "int24 -> int256" is left-padded with 1 but not 0.
        tickSlot = keccak256(abi.encodePacked(uint256(int256(tickIdx)), tierTicksSlot));
    }
}

/**
 * For building in-memory dynamic-sized bytes32 array
 */
library Bytes32ArrayLib {
    uint256 internal constant CHUNK_SIZE = 100;

    struct Bytes32Array {
        bytes data;
        bytes32[CHUNK_SIZE] chunk;
        uint256 i;
        uint256 length;
    }

    function push(Bytes32Array memory self, bytes32 word) internal pure {
        self.chunk[self.i] = word;
        self.i++;
        self.length++;

        if (self.i == CHUNK_SIZE) {
            self.data = bytes.concat(self.data, abi.encodePacked(self.chunk));
            self.i = 0;
            delete self.chunk;
        }
    }

    function end(Bytes32Array memory self) internal pure {
        if (self.i != 0) {
            bytes32[] memory trimmed = new bytes32[](self.i);
            for (uint256 j; j < trimmed.length; j++) {
                trimmed[j] = self.chunk[j];
            }
            self.data = bytes.concat(self.data, abi.encodePacked(trimmed));
            self.i = 0;
            delete self.chunk;
        }
    }
}