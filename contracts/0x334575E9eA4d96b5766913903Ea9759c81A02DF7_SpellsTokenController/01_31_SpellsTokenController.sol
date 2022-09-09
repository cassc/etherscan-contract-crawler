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

import { ERC165Storage } from "@solidstate/contracts/introspection/ERC165Storage.sol";

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { ISpellsCoin } from "../../coin/ISpellsCoin.sol";
import { ECDSA } from "../../helpers/ECDSA.sol";
import { SpellsCastStorage } from "./SpellsCastStorage.sol";
import { SpellsStorage } from "./SpellsStorage.sol";
import { ERC721Checkpointable } from "./ERC721Checkpointable/ERC721Checkpointable.sol";
import {ERC721AQueryableUpgradeable} from "./ERC721A/extensions/ERC721AQueryableUpgradeable.sol";
import { CallProtection } from "./shared/Access/CallProtection.sol";
import { LinearVRGDA } from "./VRGDA/LinearVRGDA.sol";
import { toDaysWadUnsafe } from  "./VRGDA/math/SignedWadMath.sol";
import { ReentryProtection } from "./shared/reentry/ReentryProtection.sol";
import { ERC721Checkpointable } from "./ERC721Checkpointable/ERC721Checkpointable.sol";


contract SpellsTokenController is ReentryProtection, CallProtection {
    
    event GodspellUpdated(address godspell);
    
    error SenderNotGodspell();
    
    function setSpellGate(address _spellGate) external protectedCall {
        SpellsStorage.getStorage().spellGate = _spellGate;
    }

    function getSpellGate() external view returns (address) {
        return SpellsStorage.getStorage().spellGate;
    }
    
    modifier onlyGodspell() {
         if(msg.sender != SpellsStorage.getStorage().godspell) revert SenderNotGodspell();
        _;
    }
   
    /**
    * @notice Set the godspell.
    * @dev Only callable by the godspell.
    */
   function setGodsepll(address _godspell) external onlyGodspell {
       SpellsStorage.getStorage().godspell = _godspell;
       emit GodspellUpdated(_godspell);
   }

   /**
    * @dev Sets sale state to CLOSED (0), PRESALE (1), or OPEN (2).
    */
   function setSaleState(uint8 _state) external protectedCall {
       SpellsStorage.getStorage().saleState = SpellsStorage.SaleState(
           _state
       );
   }

   function getSaleState() external view returns (uint8 _state) {
       return uint8(SpellsStorage.getStorage().saleState);
   }

   function setPrice(uint256 price_) external protectedCall {
       SpellsStorage.getStorage().seedMintPrice = price_;
   }
   
}