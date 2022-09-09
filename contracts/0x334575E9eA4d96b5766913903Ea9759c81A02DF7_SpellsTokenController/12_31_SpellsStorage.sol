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

library SpellsStorage {
    bytes32 constant SPELLS_TOKEN_STORAGE_POSITION =
        keccak256("spells.token.storage.location");

    // Minting sale state
    enum SaleState {
        CLOSED,
        PRESALE,
        OPEN,
        ETERNAL
    }

    struct Storage {
        uint256 seedMintPrice;
        // Token supply
        uint256 seedSupply;
        // Mint key limit counter
        mapping(address => uint256) mintCounts;
        // Token minting state
        SaleState saleState;
        // Spell gate
        address spellGate;
        // Godspell (founders)
        address godspell;
        // Spell random seeds
        mapping(uint256 => uint256) tokenSeed;
        // Last seed value
        uint256 seed;
        // Eternal mint start time
        uint256 eternalStartTime;
    }

    function getStorage() internal pure returns (Storage storage es) {
        bytes32 position = SPELLS_TOKEN_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
    
    function tokenSeed(uint256 _tokenId) internal view returns (uint256) {
        return getStorage().tokenSeed[_tokenId];
    }
    
    function initialSpellsCoinOf(uint256 _tokenId) internal view returns (uint256) {
        uint256 greatness = getStorage().tokenSeed[_tokenId] % 21;
        return greatness / 4 + 1;
    }
    
    function mineOpCap(uint256 _tokenId) internal view returns (uint256) {
        uint256 initial = initialSpellsCoinOf(_tokenId);
        return initial * 2;
    }
}