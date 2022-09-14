// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../lib_constants/TraitDefs.sol";
import "../extensions/Owner.sol";
import "../lib_env/Mainnet.sol";

interface IOptionsContract {
  function getOption(uint256) external pure returns (uint8);
}

contract TraitsUtility is Owner {
  mapping(uint8 => address) optionsContracts;

  constructor() {
    _owner = msg.sender;

    // once optionContracts are live, initialize automatically here
    optionsContracts[TraitDefs.SPECIES] = Mainnet.OptionSpecies;
    optionsContracts[TraitDefs.LOCALE] = Mainnet.OptionLocale;
    optionsContracts[TraitDefs.BELLY] = Mainnet.OptionBelly;
    optionsContracts[TraitDefs.EYES] = Mainnet.OptionEyes;
    optionsContracts[TraitDefs.MOUTH] = Mainnet.OptionMouth;
    optionsContracts[TraitDefs.NOSE] = Mainnet.OptionNose;
    optionsContracts[TraitDefs.CLOTHING] = Mainnet.OptionClothing;
    optionsContracts[TraitDefs.HAT] = Mainnet.OptionHat;
    optionsContracts[TraitDefs.JEWELRY] = Mainnet.OptionJewelry;
    optionsContracts[TraitDefs.FOOTWEAR] = Mainnet.OptionFootwear;
    optionsContracts[TraitDefs.ACCESSORIES] = Mainnet.OptionAccessories;
    optionsContracts[TraitDefs.FACE_ACCESSORY] = Mainnet.OptionFaceAccessory;
    optionsContracts[TraitDefs.BACKGROUND] = Mainnet.OptionBackground;
  }

  function setOptionContract(uint8 traitDef, address optionContract)
    external
    onlyOwner
  {
    optionsContracts[traitDef] = optionContract;
  }

  function getOption(uint8 traitDef, uint256 dna)
    external
    view
    returns (uint8)
  {
    return IOptionsContract(optionsContracts[traitDef]).getOption(dna);
  }
}