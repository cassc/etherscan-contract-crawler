// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title WinningEntrySearchLogic
 * @notice This contract contains the logic to search for a winning entry.
 * @author LooksRare protocol team (👀,💎)
 */
contract WinningEntrySearchLogic {
    /**
     * @param currentEntryIndex The current entry index.
     * @param winningEntry The winning entry.
     * @param winningEntriesBitmap The bitmap of winning entries.
     */
    function _incrementWinningEntryUntilThereIsNotADuplicate(
        uint256 currentEntryIndex,
        uint256 winningEntry,
        uint256[] memory winningEntriesBitmap
    ) internal pure returns (uint256, uint256[] memory) {
        uint256 bucket = winningEntry >> 8;
        uint256 mask = 1 << (winningEntry & 0xff);
        while (winningEntriesBitmap[bucket] & mask != 0) {
            if (winningEntry == currentEntryIndex) {
                bucket = 0;
                winningEntry = 0;
            } else {
                winningEntry += 1;
                if (winningEntry % 256 == 0) {
                    unchecked {
                        bucket += 1;
                    }
                }
            }

            mask = 1 << (winningEntry & 0xff);
        }

        winningEntriesBitmap[bucket] |= mask;

        return (winningEntry, winningEntriesBitmap);
    }
}