/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "hardhat/console.sol";

library BitMathLiquidity {
    function isSoRemoveable(int128 soRemoveable, uint256 index)
        internal
        view
        returns (bool hasNotSupply)
    {
        if (index == 127 || index == 255) return hasNotSupply = true;

        if (index < 127) {
            return
                hasNotSupply =
                    uint256(int256(soRemoveable)) &
                        (1 << uint256(int256(index))) !=
                    0;
        }

        if (index > 127) {
            return
                hasNotSupply =
                    uint256(int256(soRemoveable)) &
                        (1 << ((getIndexOrderOfSell(index)))) !=
                    0;
        }
    }

    // manually tested on Remix
    function packInt128AndIn128(
        int128 soRemovablePosBuy,
        int128 soRemovablePosSell
    ) internal pure returns (int256) {
        return
            ((int256(soRemovablePosSell)) << 128) | (int256(soRemovablePosBuy));
    }

    function getPosOfSell(uint128 pos) internal pure returns (uint8) {
        return uint8(pos + 128);
    }

    function getIndexOrderOfSell(uint256 index) internal pure returns (uint8) {
        return uint8(index - 128);
    }
}