// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IAdventureApproval.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title VillainCustodian
 * @author Limit Break, Inc.
 * @notice Holds masked villain and potion tokens that are currently on a villain unmasking adventure.
 */
contract VillainCustodian {

    /// @dev Specify the villain unmasking adventure, masked villain, super villain potion and villain potion contract addresses during creation
    constructor(address villainUnmaskingAdventure, address maskedVillainAddress, address superVillainPotionAddress, address villainPotionAddress) {
        IERC721(maskedVillainAddress).setApprovalForAll(villainUnmaskingAdventure, true);
        IERC721(superVillainPotionAddress).setApprovalForAll(villainUnmaskingAdventure, true);
        IERC721(villainPotionAddress).setApprovalForAll(villainUnmaskingAdventure, true);
        IAdventureApproval(maskedVillainAddress).setAdventuresApprovedForAll(villainUnmaskingAdventure, true);
        IAdventureApproval(superVillainPotionAddress).setAdventuresApprovedForAll(villainUnmaskingAdventure, true);
        IAdventureApproval(villainPotionAddress).setAdventuresApprovedForAll(villainUnmaskingAdventure, true);
    }
}