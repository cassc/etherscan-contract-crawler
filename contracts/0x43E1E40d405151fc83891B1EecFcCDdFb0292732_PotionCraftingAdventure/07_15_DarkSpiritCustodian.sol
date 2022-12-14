// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IAdventureApproval.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title DarkSpiritCustodian
 * @author Limit Break, Inc.
 * @notice Holds dark spirit and dark hero spirit tokens that are currently on potion crafting quest.
 */
contract DarkSpiritCustodian {

    /// @dev Specify the potion crafting adventure, dark spririt, and dark hero spirit token contract addresses during creation
    constructor(address potionCraftingAdventure, address darkSpiritsAddress, address darkHeroSpiritsAddress) {
        IERC721(darkSpiritsAddress).setApprovalForAll(potionCraftingAdventure, true);
        IERC721(darkHeroSpiritsAddress).setApprovalForAll(potionCraftingAdventure, true);
        IAdventureApproval(darkSpiritsAddress).setAdventuresApprovedForAll(potionCraftingAdventure, true);
        IAdventureApproval(darkHeroSpiritsAddress).setAdventuresApprovedForAll(potionCraftingAdventure, true);
    }
}