// contracts/interfaces/ISplitManager.sol
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface ISplitManager {
    /**
     * @notice Register a split
     * @dev The first ID and first splitPart must contain the locked part
     * @param originId ID-NFT to be divided
     * @param splitedIds New IDs
     * @param splitParts Split proportions normalized
     */
    function registerSplit(uint256 originId, uint256[] memory splitedIds, uint256[] memory splitParts) external returns(bool);

    /**
     * @notice Get the locked part of a NFT/Deposit
     * @param ID ID-NFT to see the locked part
     * @return lockedPart locked part proportion normalized
     */
    function getLockedPart(uint256 ID) view external returns(uint256 lockedPart);

    /**
     * @notice Get the unlocked part of a NFT/Deposit
     * @param ID ID-NFT to see the locked part
     * @return unlockedPart unlocked part proportion normalized
     */
    function getUnlockedPart(uint256 ID) view external returns(uint256 unlockedPart);
}