// SPDX-License-Identifier: MIT

/*********************************************************
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░  .░░░░░░░░░░░░░░░░░░░░░░░░.  ҹ░░░░░░░░░░░░*
*░░░░░░░░░░░░░  ∴░░░░░░░░░░░░░░░░░░`   ░░․  ░░∴   (░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º   ҹ  ░   (░░░░░░░░*
*░░░░░⁕  .░░░░░░░░░░░░░░░░░░░░░░░     ⁕..    .∴,    ⁕░░░░*
*░░░░░░  ∴░░░░░░░░░░░░░░░░░░░░░░░ҹ ,(º⁕ҹ     ․∴ҹ⁕(. ⁕░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º`  ․░  ⁕,   ░░░░░░░░*
*░░░░░,  .░░░░░░░░░░░░░░░░░░░░░░░░░`  ,░░⁕  ∴░░   `░░░░░░*
*░░░░░░⁕º░░░░░░░░░░░░░░⁕   ҹ░░░░░░░░░░░░░,  %░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░ҹ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░ҹ   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░º(░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*********************************************************/

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../../coin/ISpellsCoin.sol";

library SpellsCastStorage {
    bytes32 constant SPELLS_CAST_STORAGE_POSITION =
        keccak256("spells.cast.storage.location");

    bytes4 public constant _CAST_SELECTOR = bytes4(keccak256("cast"));

    struct Storage {
        ISpellsCoin spellsCoin;
        mapping(uint256 => uint256) tokenSpellsCoinMined;
        mapping(address => uint256) contractCastings;
        mapping(uint256 => uint256) factions;
        uint256 spellsCoinMultiplier;
        mapping(address => uint256) contractCasts;
        mapping(address => bool) tys;
        uint256 tyClaimThreshold;
        uint256 tyjackpot;
        uint256 tyfirstSolveBonus;
    }

    function getStorage() internal pure returns (Storage storage es) {
        bytes32 position = SPELLS_CAST_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
    
    function CAST_SELECTOR() internal pure returns (bytes4) {
        return _CAST_SELECTOR;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function initialSpellsCoinOf(uint256 seed) internal pure returns (uint256) {
        uint256 rand = random(Strings.toString(seed));
        uint256 greatness = rand % 21;
        return greatness / 4 + 1;
    }
}