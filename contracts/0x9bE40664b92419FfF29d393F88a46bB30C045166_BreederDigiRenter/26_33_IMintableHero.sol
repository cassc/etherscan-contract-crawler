// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Bloodlines.sol";

/**
 * @dev Required interface of mintable hero contracts.
 */
interface IMintableHero {
    /**
     * @notice Mints a hero with a specified token id and genesis token id
     */
    function mintHero(address to, uint256 tokenId, uint256 genesisTokenId)
        external;
}