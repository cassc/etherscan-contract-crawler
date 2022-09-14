// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// Assets & Layers
import "../lib_constants/TraitDefs.sol";
import "../lib_env/Mainnet.sol";

// Internal Extensions
import "../extensions/Owner.sol";

struct TraitOptions {
  uint8 accessories;
  uint8 background;
  uint8 belly;
  uint8 clothing;
  uint8 eyes;
  uint8 faceAccessory;
  uint8 footwear;
  uint8 hat;
  uint8 jewelry;
  uint8 locale;
  uint8 mouth;
  uint8 nose;
  uint8 species;
}

interface IAnimationUtility {
  function animationURI(uint256 dna) external view returns (bytes memory);
}

interface ITraitsUtility {
  function getOption(uint8 traitDef, uint256 dna) external pure returns (uint8);
}

interface ITraitOptionsLabel {
  function getLabel(uint8 optionNum) external pure returns (string memory);
}

contract Metadata is Owner {
  using Strings for uint256;

  mapping(uint8 => address) public traitOptionLabelContracts;
  address traitsUtility;
  address animationUtility;

  string baseImageURI = "https://www.mergebears.com/api/bears/";

  constructor() {
    // pre-link traitOptionLabel contracts
    traitOptionLabelContracts[TraitDefs.ACCESSORIES] = Mainnet
      .TraitOptionLabelsAccessories;
    traitOptionLabelContracts[TraitDefs.BACKGROUND] = Mainnet
      .TraitOptionLabelsBackground;
    traitOptionLabelContracts[TraitDefs.BELLY] = Mainnet.TraitOptionLabelsBelly;
    traitOptionLabelContracts[TraitDefs.CLOTHING] = Mainnet
      .TraitOptionLabelsClothing;
    traitOptionLabelContracts[TraitDefs.EYES] = Mainnet.TraitOptionLabelsEyes;
    traitOptionLabelContracts[TraitDefs.FACE_ACCESSORY] = Mainnet
      .TraitOptionLabelsFaceAccessory;
    traitOptionLabelContracts[TraitDefs.FOOTWEAR] = Mainnet
      .TraitOptionLabelsFootwear;
    traitOptionLabelContracts[TraitDefs.HAT] = Mainnet.TraitOptionLabelsHat;
    traitOptionLabelContracts[TraitDefs.JEWELRY] = Mainnet
      .TraitOptionLabelsJewelry;
    traitOptionLabelContracts[TraitDefs.LOCALE] = Mainnet
      .TraitOptionLabelsLocale;
    traitOptionLabelContracts[TraitDefs.MOUTH] = Mainnet.TraitOptionLabelsMouth;
    traitOptionLabelContracts[TraitDefs.NOSE] = Mainnet.TraitOptionLabelsNose;
    traitOptionLabelContracts[TraitDefs.SPECIES] = Mainnet
      .TraitOptionLabelsSpecies;

    // Utility linker
    traitsUtility = Mainnet.TraitsUtility;
    animationUtility = Mainnet.Animation;
  }

  function setTraitOptionLabelContract(
    uint8 traitDefId,
    address traitOptionLabelContract
  ) external onlyOwner {
    traitOptionLabelContracts[traitDefId] = traitOptionLabelContract;
  }

  function setTraitsUtility(address traitsUtilityContract) external onlyOwner {
    traitsUtility = traitsUtilityContract;
  }

  function setAnimationUtility(address animationContract) external onlyOwner {
    animationUtility = animationContract;
  }

  function setBaseImageURI(string memory newURI) external onlyOwner {
    baseImageURI = newURI;
  }

  function getTraitOptions(uint256 dna)
    internal
    view
    returns (TraitOptions memory)
  {
    TraitOptions memory traitOptions;

    traitOptions.eyes = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.EYES,
      dna
    );

    traitOptions.faceAccessory = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.FACE_ACCESSORY,
      dna
    );

    traitOptions.hat = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.HAT,
      dna
    );
    traitOptions.mouth = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.MOUTH,
      dna
    );
    traitOptions.nose = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.NOSE,
      dna
    );

    traitOptions.accessories = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.ACCESSORIES,
      dna
    );

    traitOptions.background = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.BACKGROUND,
      dna
    );

    traitOptions.belly = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.BELLY,
      dna
    );

    traitOptions.clothing = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.CLOTHING,
      dna
    );

    traitOptions.footwear = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.FOOTWEAR,
      dna
    );

    traitOptions.jewelry = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.JEWELRY,
      dna
    );

    traitOptions.locale = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.LOCALE,
      dna
    );

    traitOptions.species = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.SPECIES,
      dna
    );

    return traitOptions;
  }

  function getAttribute(uint8 traitDefId, uint8 traitOptionNum)
    internal
    view
    returns (string memory)
  {
    string memory traitType;
    string memory value = ITraitOptionsLabel(
      traitOptionLabelContracts[traitDefId]
    ).getLabel(traitOptionNum);

    if (traitDefId == TraitDefs.SPECIES) {
      traitType = "Species";
    } else if (traitDefId == TraitDefs.LOCALE) {
      traitType = "Locale";
    } else if (traitDefId == TraitDefs.BELLY) {
      traitType = "Belly";
    } else if (traitDefId == TraitDefs.EYES) {
      traitType = "Eyes";
    } else if (traitDefId == TraitDefs.MOUTH) {
      traitType = "Mouth";
    } else if (traitDefId == TraitDefs.NOSE) {
      traitType = "Nose";
    } else if (traitDefId == TraitDefs.CLOTHING) {
      traitType = "Clothing";
    } else if (traitDefId == TraitDefs.HAT) {
      traitType = "Hat";
    } else if (traitDefId == TraitDefs.JEWELRY) {
      traitType = "Jewelry";
    } else if (traitDefId == TraitDefs.FOOTWEAR) {
      traitType = "Footwear";
    } else if (traitDefId == TraitDefs.ACCESSORIES) {
      traitType = "Accessories";
    } else if (traitDefId == TraitDefs.FACE_ACCESSORY) {
      traitType = "Face Accessory";
    } else if (traitDefId == TraitDefs.BACKGROUND) {
      traitType = "Background";
    }

    return
      string.concat(
        '{ "trait_type": "',
        traitType,
        '",',
        '"value":"',
        value,
        '"}'
      );
  }

  function getAttributes(uint256 dna) internal view returns (string memory) {
    string memory attributes = "";
    // get trait defs from dna
    TraitOptions memory traitOptions = getTraitOptions(dna);

    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.SPECIES, traitOptions.species),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.LOCALE, traitOptions.locale),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.BELLY, traitOptions.belly),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.EYES, traitOptions.eyes),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.MOUTH, traitOptions.mouth),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.NOSE, traitOptions.nose),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.CLOTHING, traitOptions.clothing),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.HAT, traitOptions.hat),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.JEWELRY, traitOptions.jewelry),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.FOOTWEAR, traitOptions.footwear),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.ACCESSORIES, traitOptions.accessories),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.FACE_ACCESSORY, traitOptions.faceAccessory),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.BACKGROUND, traitOptions.background)
    );

    //must return JSONified array
    return string.concat("[", attributes, "]");
  }

  function getAnimationURI(uint256 dna) public view returns (string memory) {
    return string(IAnimationUtility(animationUtility).animationURI(dna));
  }

  function getMetadataFromDNA(uint256 dna, uint256 tokenId)
    public
    view
    returns (string memory)
  {
    // prettier-ignore
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            abi.encodePacked(
              "{",
                '"name":"MergeBears #', tokenId.toString(), '",',
                '"external_url":"https://www.mergebears.com",',
                '"image":', string.concat('"', baseImageURI, tokenId.toString(), '",'),
                '"animation_url":"', IAnimationUtility(animationUtility).animationURI(dna), '",',
                '"attributes":', getAttributes(dna),
              "}"
            )
          )
        )
      );
  }
}