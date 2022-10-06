//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MetarunCollection.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Metarun swap
 * @dev Ensures exchange of ticket for classic common character
 */

contract SwapTicket is Initializable {
    MetarunCollection public collection;

    uint256 public IGNIS_CLASSIC_COMMON;
    uint256 public PENNA_CLASSIC_COMMON;
    uint256 public ORO_CLASSIC_COMMON;

    uint256 public currentCharacterKind;

    mapping(uint256 => uint256) public currentIds;

    event SwapTicketToCharacter(address owner, uint256 ticketId, uint256 characterId);

    /**
     * @dev the constructor arguments:
     * @param _collection address of collection token
     */

    function initialize(address _collection) public initializer {
        require(_collection != address(0), "Empty collection token address");
        collection = MetarunCollection(_collection);
        IGNIS_CLASSIC_COMMON = collection.IGNIS_CLASSIC_COMMON();
        PENNA_CLASSIC_COMMON = collection.PENNA_CLASSIC_COMMON();
        ORO_CLASSIC_COMMON = collection.ORO_CLASSIC_COMMON();
        currentCharacterKind = IGNIS_CLASSIC_COMMON;
    }

    function swapTicketToCharacter(uint256 ticketId) external {
        require(_isTicket(ticketId), "Incorrect ticket id");
        uint256 characterId = _getNextCharacter();
        collection.burn(msg.sender, ticketId, 1);
        collection.mint(msg.sender, characterId, 1);

        emit SwapTicketToCharacter(msg.sender, ticketId, characterId);
    }

    function _isTicket(uint256 id) internal view returns (bool) {
        return
            collection.isKind(id, collection.BRONZE_TICKET_KIND()) ||
            collection.isKind(id, collection.SILVER_TICKET_KIND()) ||
            collection.isKind(id, collection.GOLD_TICKET_KIND());
    }

    function _getNextCharacter() internal returns (uint256) {
        uint256 tokenKind = _getNextTokenKind();
        uint256 tokenId = ((tokenKind << 16) | (currentIds[tokenKind]));

        while (collection.exists(tokenId)) {
            tokenId += 1;
            currentIds[tokenKind] += 1;
        }
        currentIds[tokenKind] += 1;

        return tokenId;
    }

    function _getNextTokenKind() internal returns (uint256) {
        uint256 tokenKind = currentCharacterKind;

        if (currentCharacterKind == IGNIS_CLASSIC_COMMON) {
            currentCharacterKind = PENNA_CLASSIC_COMMON;
        } else if (currentCharacterKind == PENNA_CLASSIC_COMMON) {
            currentCharacterKind = ORO_CLASSIC_COMMON;
        } else {
            currentCharacterKind = IGNIS_CLASSIC_COMMON;
        }

        return tokenKind;
    }
}