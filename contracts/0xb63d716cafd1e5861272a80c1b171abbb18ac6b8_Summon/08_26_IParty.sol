// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/Stats.sol";

interface IParty {
    event Equipped(address indexed user, uint8 item, uint8 slot, uint256 id);

    event Unequipped(address indexed user, uint8 item, uint8 slot, uint256 id);

    event DamageUpdated(address indexed user, uint32 damageCurr);

    struct PartyData {
        uint256 hero;
        mapping(uint256 => uint256) fighters;
    }

    struct Action {
        ActionType action;
        uint256 id;
        uint8 slot;
    }

    enum Property {
        HERO,
        FIGHTER
    }

    enum ActionType {
        UNEQUIP,
        EQUIP
    }

    function act(
        Action[] calldata heroActions,
        Action[] calldata fighterActions
    ) external;

    function equip(
        Property item,
        uint256 id,
        uint8 slot
    ) external;

    function unequip(Property item, uint8 slot) external;

    function enhance(
        Property item,
        uint8 slot,
        uint256 burnTokenId
    ) external;

    function getUserHero(address user) external view returns (uint256);

    function getUserFighters(address user)
        external
        view
        returns (uint256[] memory);

    function getDamage(address user) external view returns (uint32);

    function updateDamage(address user) external;
}