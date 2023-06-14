// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "@openzeppelin/contracts/utils/Strings.sol";
import "./GridHelper.sol";
import "./GlobalNumbers.sol";
import "./AssetRetriever.sol";

interface IMachine {
  function getMachine(uint rand, int baseline) external view returns (string memory);
  function getAllNumbersUsed(uint rand, int baseline) external pure returns (uint[] memory, string[] memory);
  function getGlobalAssetNumber(uint rand, uint version, int baseline) external pure returns (uint);
}

contract Machine {

  AssetRetriever internal immutable _assetRetriever;

  string[] public allMachines = ["Altar", "Apparatus", "Cells", "Tubes", "Beast", "Conveyor"];

  mapping(string => address) public machineToWorkstation;

  constructor(address[6] memory workstations, AssetRetriever assetRetriever) {
    _assetRetriever = assetRetriever;

    for (uint i = 0; i < allMachines.length; ++i) {
      machineToWorkstation[allMachines[i]] = workstations[i];
    }
  }

  /**
    * @dev Returns the machine based on the random number
    * @param rand The digits to use
    * @return The machine
   */

  function selectMachine(uint rand) external view returns (string memory) {
      return allMachines[rand % allMachines.length];
      // return allMachines[5];
  }

  /**
    * @dev Get a machine based on the random number
    * @param machine The machine to get
    * @param rand The digits to use
    * @param baseline The baseline rarity
   */

  function machineToGetter(string memory machine, uint rand, int baseline) external view returns (string memory) {
    return IMachine(machineToWorkstation[machine]).getMachine(rand, baseline);
  }

  /**
    * @dev Get the global asset name based on the random number
    * @param rand The digits to use
    * @param baseline The baseline rarity
    * @return The global asset name
   */

  function getSmallAssetName(uint rand, int baseline) external pure returns (string memory) {
    uint assetNumber = GlobalNumbers.getSmallAssetNumber(rand, baseline);

    if (assetNumber == 6000) {
      return "Lava Lamp";
    } else if (assetNumber == 6004) {
      return "Martini";
    } else if (assetNumber == 6006) {
      return "Bong";
    } else if (assetNumber == 6011) {
      return "Books";
    } else if (assetNumber == 6014) {
      return "Dog Bowl";
    } else if (assetNumber == 6020) {
      return "Lizard";
    } else if (assetNumber == 6021) {
      return "Skull";
    } else if (assetNumber == 6022) {
      return "Dead Rat";
    } else if (assetNumber == 6025) {
      return "Pineapple";
    } else if (assetNumber == 6026) {
      return "Can";
    } else if (assetNumber == 6027) {
      return "Cracked Bottle";
    } else if (assetNumber == 6028) {
      return "Dead Plant";
    } else if (assetNumber == 6029) {
      return "Watermelon";
    } else {
      return "None";
    }
  }

  /**
    * @dev Get the expansion prop name based on the random number
    * @param rand The digits to use
    * @param baseline The baseline rarity
    * @return The expansion prop name
   */

  function getLargeAssetName(uint rand, int baseline) external pure returns (string memory) {
    uint propNumber = GlobalNumbers.getLargeAssetNumber(rand, baseline);

    if (propNumber == 2001) {
      return "Grate";
    } else if (propNumber == 2002) {
      return "Pit";
    } else if (propNumber == 2003) {
      return "Stairs";
    } else if (propNumber == 2004) {
      return "Ladder";
    } else if (propNumber == 2008) {
      return "Spikes A";
    } else if (propNumber == 2009) {
      return "Spikes B";
    } else if (propNumber == 6008) {
      return "Fridge";
    } else if (propNumber == 6009) {
      return "Rug Circle";
    } else if (propNumber == 6013) {
      return "Toilet";
    } else if (propNumber == 6017) {
      return "Harp";
    } else if (propNumber == 6018) {
      return "Cello";
    } else if (propNumber == 6019) {
      return "Stool";
    } else if (propNumber == 6023) {
      return "Deck Chair";
    } else if (propNumber == 6024) {
      return "Cactus Chunk";
    } else if (propNumber == 6030) {
      return "Gramophone";
    } else {
      return "None";
    }
  }

  /**
    * @dev Get the wall prop name based on the random number
    * @param rand The digits to use
    * @param baseline The baseline rarity
    * @return The wall out name
   */

  function getWallOutName(uint rand, int baseline) external pure returns (string memory) {
    uint wallOutNumber = GlobalNumbers.getOutWallNumber(rand, baseline);

    if (wallOutNumber == 6005) {
      return "Peephole A";
    } else if (wallOutNumber == 6007) {
      return "Peephole B";
    } else if (wallOutNumber == 6010) {
      return "CCTV";
    } else if (wallOutNumber == 6016) {
      return "Megaphone";
    } else {
      return "None";
    }
  }

  /**
    * @dev Get the wall flat name based on the random number
    * @param rand The digits to use
    * @param baseline The baseline rarity
    * @return The wall flat name
   */
  
  function getWallFlatName(uint rand, int baseline) external pure returns (string memory) {
    uint wallFlatNumber = GlobalNumbers.getFlatWallNumber(rand, baseline);

    if (wallFlatNumber == 2000) {
      return "Crack";
    } else if (wallFlatNumber == 2005) {
      return "Recess A";
    } else if (wallFlatNumber == 2006) {
      return "Recess B";
    } else if (wallFlatNumber == 2007) {
      return "Recess C";
    } else if (wallFlatNumber == 2010) {
      return "Wall Rug";
    } else if (wallFlatNumber == 2011) {
      return "Numbers";
    } else {
      return "None";
    }
  }

  /**
    * @dev Get the character name based on the random number
    * @param rand The digits to use
    * @param baseline The baseline rarity
    * @return The character name
   */

  function getCharacterName(uint rand, int baseline) external pure returns (string memory) {
    uint characterNumber = GlobalNumbers.getCharacterNumber(rand, baseline);

    if (characterNumber == 14000) {
      return "Sitting";
    } else if (characterNumber == 14001) {
      return "Standing";
    } else if (characterNumber == 14002) {
      return "Collapsed";
    } else if (characterNumber == 14003) {
      return "Slouched";
    } else if (characterNumber == 14004) {
      return "Meditating";
    } else if (characterNumber == 14005) {
      return "Hunched";
    } else {
      return "None";
    }
  }
}