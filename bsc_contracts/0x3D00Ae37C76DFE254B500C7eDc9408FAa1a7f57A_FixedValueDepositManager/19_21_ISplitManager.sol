// contracts/interfaces/ISplitManager.sol
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ISplitManager {
    /**
     * @notice Register a split
     * @dev The first ID and first splitPart must contain the locked part
     * @param originId ID-NFT to be divided
     * @param splitedIds New IDs
     * @param splitParts Split proportions normalized
     */
    function registerSplit(uint originId, uint[] memory splitedIds, uint[] memory splitParts) external returns(bool);

    /**
     * @notice Get the locked part of a NFT/Deposit
     * @param ID ID-NFT to see the locked part
     * @return The locked part proportion normalized
     */
    function getLockedPart(uint ID) view external returns(uint);
}