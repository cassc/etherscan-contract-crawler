// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface ILock is IERC721Upgradeable {
    function splitManager() external view returns (address);

    /**
     * @notice Get all the information about a NFT with specific ID
     * @param id NFT ID of the NFT for which the information is required
     * @return Owner or beneficiary of the NFT
     * @return The actual balance of amount locked
     * @return The actual amount that the owner can claim
     * @return The time when the lock start
     * @return The time when the lock will end
     */
    function getInfoBySingleID(uint id) external view returns (address, uint, uint, uint, uint);

    /**
     * @notice Get all the information about a set of IDs
     * @param ids List of NFT IDs which the information is required
     * @return List of owners or beneficiaries
     * @return List of actual balance of amount locked
     * @return List of actual amount that is claimable
     */
    function getInfoByManyIDs(uint[] memory ids) external view returns (address[] memory, uint[] memory, uint[] memory);

    /**
     * @notice Split a NFT
     * @param originId NFT ID to be split
     * @param splitParts List of proportions normalized to be used in the split
     * @param addresses List of addresses of beneficiaries
     * @return newIDs of minted NFTs in order
     */
    function split(
        uint originId,
        uint[] memory splitParts,
        address[] memory addresses
    ) external returns (uint256[] memory);
}