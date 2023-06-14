// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "solady/utils/Base64.sol";
import "./Machine.sol";
import "./GridHelper.sol";
import "./GlobalSVG.sol";
import "./Noise.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Metadata {
  Machine private immutable _machine;
  // Clifford private _clifford;
  GlobalSVG private immutable _globalSVG;

  string[3] allStates = ["Degraded", "Basic", "Embellished"];

  constructor(Machine machine, GlobalSVG globalSVG) {
      _machine = machine;
      _globalSVG = globalSVG;
  }

  /**
    * @dev Returns the machine based on the random number
    * @param rand The digits to use
    * @return The machine
   */

  function getMachine(uint rand) public view returns (string memory) {
    return _machine.selectMachine(rand);
  }

  /**
   * @dev build entire metadata for a given token
    * @param tokenId The token to build metadata for
    * @param rand The digits to use
    * @return The metadata
  */

  function buildMetadata(uint256 tokenId, uint rand) public view returns (string memory) {
    int baseline = getBaselineRarity(rand);
    uint state = getState(baseline);
    string memory jsonInitial = string.concat(
        '{"name": "A Machine For Dying # ',
        Strings.toString(tokenId),
        '", "description": "A Machine For Dying is centred around the concept of the Worker in a Box, a trapped individual, doomed to toil forever. The collection presents the stark contrast between autonomy and individuality versus the destruction and apathy that can come from being trapped and exploited by the corporate machine.", "attributes": [{"trait_type": "Machine", "value":"',
        getMachine(rand),
        '"}, {"trait_type": "State", "value":"',
        allStates[state],
        '"}, {"trait_type": "Small Asset:", "value":"',
        _machine.getSmallAssetName(rand, baseline)
    );

    jsonInitial = string.concat(
      jsonInitial,
      '"}, {"trait_type": "Large Asset:", "value":"',
      _machine.getLargeAssetName(rand, baseline),
      '"}, {"trait_type": "Wall Out:", "value":"',
      _machine.getWallOutName(rand, baseline),
      '"}, {"trait_type": "Wall Flat:", "value":"',
      _machine.getWallFlatName(rand, baseline)
    );

    jsonInitial = string.concat(
        jsonInitial,
        '"}, {"trait_type": "Colour:", "value":"',
        getColourIndexTier(rand, baseline),
        '"}, {"trait_type": "Pattern:", "value":"',
        Patterns.getPatternName(rand, baseline),
        '"}, {"trait_type": "Character:", "value":"',
        _machine.getCharacterName(rand, baseline),
        '"}],',
        '"image": "data:image/svg+xml;base64,'
    );

    string memory jsonFinal = Base64.encode(
      bytes(string.concat(
        jsonInitial,
        composeSVG(rand, baseline),
        '", ',
        '"animation_url": "data:image/svg+xml;base64,',
        composeSVG(rand, baseline),
        '"}'
      ))
    );

    string memory output = string.concat("data:application/json;base64,", jsonFinal);
    return output;
  }

  /**
    * @dev Inject data into the SVG for the sound script
    * @param rand The digits to use
    * @return The data info object string
   */
  function createDataInfo(uint rand) internal view returns (string memory) {
    int baseline = getBaselineRarity(rand);
    uint state = getState(baseline);
    string memory json = string.concat(
        'data-info=\'{"RandomNumber":"',
        Strings.toString(rand),
        '","State":"',
        allStates[state],
        '","Machine":"',
        getMachine(rand),
        '","SmallAsset":"',
        _machine.getSmallAssetName(rand, baseline)
    );

    json = string.concat(
      json,
      '","LargeAsset":"',
      _machine.getLargeAssetName(rand, baseline),
      '","WallOut":"',
      _machine.getWallOutName(rand, baseline),
      '","WallFlat":"',
      _machine.getWallFlatName(rand, baseline)
    );

    json = string.concat(
        json,
        '","Colour":"',
        getColourIndexTier(rand, baseline),
        '","Pattern":"',
        Patterns.getPatternName(rand, baseline),
        '","Character":"',
        _machine.getCharacterName(rand, baseline),
        '"}\' >'
    );

    return json;
  }

  /**
    * @dev Get the colour index based on the baseline rarity and random number
    * @param rand The digits to use
    * @param baseline The baseline rarity
    * @return The colour index as a string
   */

  function getBaseColourValue(uint rand, int baseline) internal pure returns (uint) {
    return GridHelper.constrainToHex(Noise.getNoiseArrayThree()[GridHelper.getRandByte(rand, 3)] + baseline);
  }

  /**
    * @dev Get the colour index tier based on the baseline rarity and random number
    * @param rand The digits to use
    * @param baseline The baseline rarity
    * @return The colour index tier as a string
   */

  function getColourIndexTier(uint rand, int baseline) public pure returns(string memory) {
    uint value = Environment.getColourIndex(getBaseColourValue(rand, baseline));

    if (value < 12) {
      return string.concat("DEG", Strings.toString(11-value));
    } else {
      return string.concat("EMB", Strings.toString(value-12));
    }
  }

  /**
    * @dev Get the state based on the baseline rarity
    * @param baseline The baseline rarity
    * @return The state as an integer
   */
  
  function getState(int baseline) public pure returns (uint) {
    // 0 = degraded, 1 = basic, 2 = embellished
    if (baseline < 85) {
      return 0;
    } else if (baseline < 171) {
      return 1;
    } else {
      return 2;
    }
  }

  /**
    * @dev Get the baseline rarity based on the random number
    * @param rand The digits to use
    * @return The baseline rarity as an integer
   */

  function getBaselineRarity(uint rand) public pure returns (int) {
    int baselineDigits = int(GridHelper.constrainToHex(Noise.getNoiseArrayZero()[GridHelper.getRandByte(rand, 2)]));
    return baselineDigits;
  }

  /**
    * @dev Get the SVG for a given token base64 encoded
    * @param rand The digits to use
    * @param baseline The baseline rarity
    * @return The SVG as a string
   */
  
  function composeSVG(uint rand, int baseline) public view returns (string memory) {
    // return all svg's concatenated together and base64 encoded
    return Base64.encode(bytes(composeOnlyImage(rand, baseline)));
  }

  /**
    * @dev Get the SVG for a given token not base64 encoded
    * @param rand The digits to use
    * @param baseline The baseline rarity
    * @return The SVG as a string
   */
  
  function composeOnlyImage(uint rand, int baseline) public view returns (string memory) {
    // determine if flipped

    // 0 if not flipped, 1 if flipped
    uint isFlipped = rand % 2;
    string memory flip = "";
    if (isFlipped == 0) {
      flip = "1";
    } else {
      flip = "-1";
    }

    string memory machine = getMachine(rand);

    uint colourValue = getBaseColourValue(rand, baseline);

    string memory dataInfo = createDataInfo(rand);

    string memory opening = _globalSVG.getOpeningSVG(machine, colourValue, rand, baseline);
    
    string memory objects = _machine.machineToGetter(machine, rand, baseline);
    string memory closing = _globalSVG.getClosingSVG();
    // return all svg's concatenated together and base64 encoded
    return string.concat(opening, _globalSVG.getShell(flip, rand, baseline, dataInfo), objects, closing);
  }
}