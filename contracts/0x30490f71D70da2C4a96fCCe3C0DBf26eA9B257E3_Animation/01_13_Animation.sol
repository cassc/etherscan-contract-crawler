// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// Assets & Layers
import "../lib_constants/AssetContracts.sol";
import "../lib_constants/LayerOrder.sol";
import "../lib_constants/TraitDefs.sol";
import "../lib_env/Mainnet.sol";

// Utilities
import "../lib_utilities/UtilAssets.sol";

// Internal Extensions
import "../extensions/Owner.sol";

interface IAssetLibrary {
  function getAsset(uint256) external pure returns (string memory);
}

interface ITraitsUtility {
  function getOption(uint8 traitDef, uint256 dna) external pure returns (uint8);
}

contract Animation is Owner {
  using Strings for uint256;

  mapping(uint8 => address) public assetContracts;
  address traitsUtility;

  constructor() {
    // pre-link asset contracts
    assetContracts[AssetContracts.ACCESSORIES] = Mainnet.ACCESSORIES;
    assetContracts[AssetContracts.ARMS] = Mainnet.ARMS;
    assetContracts[AssetContracts.BELLY] = Mainnet.BELLY;
    assetContracts[AssetContracts.CLOTHINGA] = Mainnet.CLOTHINGA;
    assetContracts[AssetContracts.CLOTHINGB] = Mainnet.CLOTHINGB;
    assetContracts[AssetContracts.EYES] = Mainnet.EYES;
    assetContracts[AssetContracts.FACE] = Mainnet.FACE;
    assetContracts[AssetContracts.FEET] = Mainnet.FEET;
    assetContracts[AssetContracts.FOOTWEAR] = Mainnet.FOOTWEAR;
    assetContracts[AssetContracts.HAT] = Mainnet.HAT;
    assetContracts[AssetContracts.HEAD] = Mainnet.HEAD;
    assetContracts[AssetContracts.JEWELRY] = Mainnet.JEWELRY;
    assetContracts[AssetContracts.MOUTH] = Mainnet.MOUTH;
    assetContracts[AssetContracts.NOSE] = Mainnet.NOSE;
    assetContracts[AssetContracts.SPECIAL_CLOTHING] = Mainnet.SPECIAL_CLOTHING;
    assetContracts[AssetContracts.SPECIAL_FACE] = Mainnet.SPECIAL_FACE;

    // Utility linker
    traitsUtility = Mainnet.TraitsUtility;
  }

  function setAssetContract(uint8 assetId, address assetContract)
    external
    onlyOwner
  {
    assetContracts[assetId] = assetContract;
  }

  function setTraitsUtility(address traitsUtilityContract) external onlyOwner {
    traitsUtility = traitsUtilityContract;
  }

  function divWithBackground(string memory dataURI)
    internal
    pure
    returns (string memory)
  {
    return
      string.concat(
        '<div class="b" style="background-image:url(data:image/png;base64,',
        dataURI,
        ')"></div>'
      );
  }

  function fetchAssetString(uint8 layer, uint256 assetNum)
    internal
    view
    returns (string memory)
  {
    // iterating in LayerOrder
    if (layer == LayerOrder.BELLY) {
      return
        IAssetLibrary(assetContracts[AssetContracts.BELLY]).getAsset(assetNum);
    } else if (layer == LayerOrder.ARMS) {
      return
        IAssetLibrary(assetContracts[AssetContracts.ARMS]).getAsset(assetNum);
    } else if (layer == LayerOrder.FEET) {
      return
        IAssetLibrary(assetContracts[AssetContracts.FEET]).getAsset(assetNum);
    } else if (layer == LayerOrder.FOOTWEAR) {
      return
        IAssetLibrary(assetContracts[AssetContracts.FOOTWEAR]).getAsset(
          assetNum
        );
      // special logic for clothing since we had to deploy two contracts to fit
    } else if (layer == LayerOrder.CLOTHING) {
      if (assetNum < 54) {
        return
          IAssetLibrary(assetContracts[AssetContracts.CLOTHINGA]).getAsset(
            assetNum
          );
      } else {
        return
          IAssetLibrary(assetContracts[AssetContracts.CLOTHINGB]).getAsset(
            assetNum
          );
      }
    } else if (layer == LayerOrder.HEAD) {
      return
        IAssetLibrary(assetContracts[AssetContracts.HEAD]).getAsset(assetNum);
    } else if (layer == LayerOrder.SPECIAL_FACE) {
      return
        IAssetLibrary(assetContracts[AssetContracts.SPECIAL_FACE]).getAsset(
          assetNum
        );
    } else if (layer == LayerOrder.EYES) {
      return
        IAssetLibrary(assetContracts[AssetContracts.EYES]).getAsset(assetNum);
    } else if (layer == LayerOrder.MOUTH) {
      return
        IAssetLibrary(assetContracts[AssetContracts.MOUTH]).getAsset(assetNum);
    } else if (layer == LayerOrder.NOSE) {
      return
        IAssetLibrary(assetContracts[AssetContracts.NOSE]).getAsset(assetNum);
    } else if (layer == LayerOrder.JEWELRY) {
      return
        IAssetLibrary(assetContracts[AssetContracts.JEWELRY]).getAsset(
          assetNum
        );
    } else if (layer == LayerOrder.HAT) {
      return
        IAssetLibrary(assetContracts[AssetContracts.HAT]).getAsset(assetNum);
    } else if (layer == LayerOrder.FACE) {
      return
        IAssetLibrary(assetContracts[AssetContracts.FACE]).getAsset(assetNum);
    } else if (layer == LayerOrder.SPECIAL_CLOTHING) {
      return
        IAssetLibrary(assetContracts[AssetContracts.SPECIAL_CLOTHING]).getAsset(
          assetNum
        );
    } else if (layer == LayerOrder.ACCESSORIES) {
      return
        IAssetLibrary(assetContracts[AssetContracts.ACCESSORIES]).getAsset(
          assetNum
        );
    }
    return "";
  }

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

  struct AssetStrings {
    string background;
    string belly;
    string arms;
    string feet;
    string footwear;
    string clothing;
    string head;
    string eyes;
    string mouth;
    string nose;
    string jewelry;
    string hat;
    string faceAccessory;
    string accessory;
  }

  struct AssetStringsBody {
    string background;
    string belly;
    string arms;
    string feet;
    string footwear;
    string clothing;
    string jewelry;
    string accessory;
  }

  struct AssetStringsHead {
    string head;
    string eyes;
    string mouth;
    string nose;
    string hat;
    string faceAccessory;
  }

  struct TraitOptionsHead {
    uint8 eyes;
    uint8 faceAccessory;
    uint8 hat;
    uint8 jewelry;
    uint8 mouth;
    uint8 nose;
  }

  function getHeadHTML(TraitOptions memory traitOptions)
    internal
    view
    returns (string memory)
  {
    AssetStringsHead memory headAssetStrings;

    headAssetStrings.head = divWithBackground(
      fetchAssetString(
        LayerOrder.HEAD,
        UtilAssets.getAssetHead(traitOptions.species, traitOptions.locale)
      )
    );
    headAssetStrings.eyes = divWithBackground(
      fetchAssetString(
        LayerOrder.EYES,
        UtilAssets.getAssetEyes(traitOptions.eyes)
      )
    );
    headAssetStrings.mouth = divWithBackground(
      fetchAssetString(
        LayerOrder.MOUTH,
        UtilAssets.getAssetMouth(traitOptions.mouth)
      )
    );
    headAssetStrings.nose = divWithBackground(
      fetchAssetString(
        LayerOrder.NOSE,
        UtilAssets.getAssetNose(traitOptions.nose)
      )
    );
    headAssetStrings.hat = divWithBackground(
      fetchAssetString(LayerOrder.HAT, UtilAssets.getAssetHat(traitOptions.hat))
    );
    headAssetStrings.faceAccessory = divWithBackground(
      fetchAssetString(
        LayerOrder.FACE,
        UtilAssets.getAssetFaceAccessory(traitOptions.faceAccessory)
      )
    );

    // return them
    return
      string.concat(
        '<div class="b h">',
        headAssetStrings.head,
        // insert special face accessories here
        headAssetStrings.eyes,
        headAssetStrings.mouth,
        headAssetStrings.nose,
        headAssetStrings.hat,
        headAssetStrings.faceAccessory,
        "</div>"
      );
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

  function animationURI(uint256 dna) external view returns (bytes memory) {
    AssetStringsBody memory assetStrings;
    TraitOptions memory traitOptions = getTraitOptions(dna);

    {
      assetStrings.background = UtilAssets.getAssetBackground(
        traitOptions.background
      );
    }
    {
      assetStrings.belly = divWithBackground(
        fetchAssetString(
          LayerOrder.BELLY,
          UtilAssets.getAssetBelly(traitOptions.species, traitOptions.belly)
        )
      );
    }
    {
      assetStrings.arms = divWithBackground(
        fetchAssetString(
          LayerOrder.ARMS,
          UtilAssets.getAssetArms(traitOptions.species)
        )
      );
    }
    {
      assetStrings.feet = divWithBackground(
        fetchAssetString(
          LayerOrder.FEET,
          UtilAssets.getAssetFeet(traitOptions.species)
        )
      );
    }
    {
      assetStrings.footwear = divWithBackground(
        fetchAssetString(
          LayerOrder.FOOTWEAR,
          UtilAssets.getAssetFootwear(traitOptions.footwear)
        )
      );
    }
    {
      assetStrings.clothing = divWithBackground(
        fetchAssetString(
          LayerOrder.CLOTHING,
          UtilAssets.getAssetClothing(traitOptions.clothing)
        )
      );
    }
    {
      assetStrings.accessory = divWithBackground(
        fetchAssetString(
          LayerOrder.ACCESSORIES,
          UtilAssets.getAssetAccessories(traitOptions.accessories)
        )
      );
    }
    {
      assetStrings.jewelry = divWithBackground(
        fetchAssetString(
          LayerOrder.JEWELRY,
          UtilAssets.getAssetJewelry(traitOptions.jewelry)
        )
      );
    }

    // TODO: Honey drip, clown face, earrings should be in face accessory
    // prettier-ignore
    return
      abi.encodePacked(
        "data:text/html;base64,",
        Base64.encode(
          abi.encodePacked(
            '<html><head><style>body,html{margin:0;display:flex;justify-content:center;align-items:center;background:', assetStrings.background, ';overflow:hidden}.a{width:min(100vw,100vh);height:min(100vw,100vh);position:relative}.b{width:100%;height:100%;background:100%/100%;image-rendering:pixelated;position:absolute}.h{animation:1s ease-in-out infinite d}@keyframes d{0%,100%{transform:translate3d(-1%,0,0)}25%,75%{transform:translate3d(0,2%,0)}50%{transform:translate3d(1%,0,0)}}</style></head><body>',
              '<div class="a">',
                assetStrings.belly,
                assetStrings.arms,
                assetStrings.feet,
                assetStrings.footwear,
                assetStrings.clothing,
                assetStrings.jewelry,
                assetStrings.accessory,
                getHeadHTML(traitOptions),
              '</div>',
            '</body></html>'
          )
        )
      );
  }
}