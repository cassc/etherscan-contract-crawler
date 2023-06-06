// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract FFInventory is Ownable, AccessControl, ReentrancyGuard {
    address public constant FLY_FISH_ADDRESS =
        0xc9D8F15803c645e98B17710a0b6593F097064bEF;

    bytes32 public constant INVENTORY_MANAGER_ROLE =
        keccak256("INVENTORY_MANAGER_ROLE");

    error RecipientsLengthMustMatchTokenIdsLength();

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(INVENTORY_MANAGER_ROLE, msg.sender);
    }

    function sendTokens(
        address[] calldata recipients,
        uint256[] calldata tokenIds
    ) external nonReentrant onlyRole(INVENTORY_MANAGER_ROLE) {
        if (recipients.length != tokenIds.length) {
            revert RecipientsLengthMustMatchTokenIdsLength();
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(FLY_FISH_ADDRESS).transferFrom(
                address(this),
                recipients[i],
                tokenIds[i]
            );
        }
    }

    function addTokensToInventory(
        uint256[] calldata tokenIds
    ) external nonReentrant onlyRole(INVENTORY_MANAGER_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(FLY_FISH_ADDRESS).transferFrom(
                _msgSender(),
                address(this),
                tokenIds[i]
            );
        }
    }
}