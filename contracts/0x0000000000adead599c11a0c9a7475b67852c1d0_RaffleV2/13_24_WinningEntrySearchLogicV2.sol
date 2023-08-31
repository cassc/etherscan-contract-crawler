// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title WinningEntrySearchLogicV2
 * @notice This contract contains the logic to search for a winning entry.
 * @author LooksRare protocol team (👀,💎)
 */
contract WinningEntrySearchLogicV2 {
    /**
     * @param randomWord The random word.
     * @param currentEntryIndex The current entry index.
     * @param winningEntriesBitmap The bitmap of winning entries.
     */
    function _searchForWinningEntryUntilThereIsNotADuplicate(
        uint256 randomWord,
        uint256 currentEntryIndex,
        uint256[] memory winningEntriesBitmap
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256[] memory
        )
    {
        uint256 winningEntry = randomWord % (currentEntryIndex + 1);

        uint256 bucket = winningEntry >> 8;
        uint256 mask = 1 << (winningEntry & 0xff);
        while (winningEntriesBitmap[bucket] & mask != 0) {
            randomWord = uint256(keccak256(abi.encodePacked(randomWord)));
            winningEntry = randomWord % (currentEntryIndex + 1);
            bucket = winningEntry >> 8;
            mask = 1 << (winningEntry & 0xff);
        }

        winningEntriesBitmap[bucket] |= mask;

        return (randomWord, winningEntry, winningEntriesBitmap);
    }
}