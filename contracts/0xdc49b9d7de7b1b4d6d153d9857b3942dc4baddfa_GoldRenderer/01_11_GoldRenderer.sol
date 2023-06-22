// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Base64} from "solady/src/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {IScriptyBuilder, WrappedScriptRequest} from "./lib/scripty/IScriptyBuilder.sol";

interface IGoldContract {
  struct TokenData {
    uint256 transferCount;
    uint256[200] latestTransferTimestamps;
    uint256 mintTimestamp;
    bytes32 seed;
  }

  // Mapping from token ID to token data
  function tokenData(
    uint256 tokenId
  ) external view returns (uint256, uint256, bytes32, address, address, address, address, address, address);

  function getSelectors() external view returns (string memory, string memory);

  function numberOfBonusPlates(uint256 tokenId) external view returns (uint256);

  function numberOfBonusClusters() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function baseTimestamp() external view returns (uint256);
}

/// @title GoldRenderer
/// @author @0x_jj
contract GoldRenderer is AccessControl {
  IGoldContract public goldContract;

  address public immutable scriptyStorageAddress;
  address public immutable scriptyBuilderAddress;
  uint256 private bufferSize;

  string public baseImageURI;

  uint256 private royaltyPct = 5;

  struct Seed {
    uint256 current;
    uint256 incrementor;
  }

  struct Trait {
    string typeName;
    string valueName;
  }

  constructor(
    address[] memory admins_,
    address _scriptyBuilderAddress,
    address _scriptyStorageAddress,
    uint256 bufferSize_,
    string memory baseImageURI_
  ) {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    for (uint256 i = 0; i < admins_.length; i++) {
      _grantRole(DEFAULT_ADMIN_ROLE, admins_[i]);
    }

    scriptyStorageAddress = _scriptyStorageAddress;
    scriptyBuilderAddress = _scriptyBuilderAddress;
    bufferSize = bufferSize_;
    baseImageURI = baseImageURI_;
  }

  function setGoldContract(address _goldContract) public onlyRole(DEFAULT_ADMIN_ROLE) {
    goldContract = IGoldContract(_goldContract);
  }

  function setBaseImageURI(string calldata uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
    baseImageURI = uri;
  }

  function setRoyaltyPct(uint256 pct) public onlyRole(DEFAULT_ADMIN_ROLE) {
    royaltyPct = pct;
  }

  function getSeedVariables(uint256 tokenId) internal view returns (uint256, uint256) {
    (, , bytes32 seed, , , , , , ) = goldContract.tokenData(tokenId);
    uint256 seedToken = uint256(seed) % (10 ** 6);
    uint256 tokenSeedIncrement = 999 + tokenId;
    return (seedToken, tokenSeedIncrement);
  }

  function numberOfBonusPlates(uint256 tokenId) public view returns (uint256) {
    uint256 count = 0;
    (
      ,
      ,
      ,
      address held6MonthsClaimedBy,
      address held12MonthsClaimedBy,
      address held24MonthsClaimedBy,
      address held60MonthsClaimedBy,
      address held120MonthsClaimedBy,
      address held240MonthsClaimedBy
    ) = goldContract.tokenData(tokenId);
    if (held6MonthsClaimedBy != address(0)) count++;
    if (held12MonthsClaimedBy != address(0)) count++;
    if (held24MonthsClaimedBy != address(0)) count++;
    if (held60MonthsClaimedBy != address(0)) count++;
    if (held120MonthsClaimedBy != address(0)) count++;
    if (held240MonthsClaimedBy != address(0)) count++;
    return count;
  }

  function numberOfBonusClusters() public view returns (uint256) {
    uint256 count = 0;
    if (block.timestamp > 1703167200) count++; // Dec 21, 2023 (6m)
    if (block.timestamp > 1718974800) count++; // Jun 21, 2024 (1y)
    if (block.timestamp > 1750510800) count++; // Jun 21, 2025 (2y)
    if (block.timestamp > 1845205200) count++; // Jun 21, 2028 (5y)
    if (block.timestamp > 2002971600) count++; // Jun 21, 2033 (10y)
    if (block.timestamp > 2318504400) count++; // Jun 21, 2043 (20y)
    return count;
  }

  function getMetadataObject(
    bytes memory animationUrl,
    uint256 tokenId
  ) internal view returns (bytes memory) {
    string memory tid = toString(tokenId);

    return
      abi.encodePacked(
        '{"name":"GOLD #',
        tid,
        '", "description":"GOLD is a dynamic cryptoart series where the artworks change in response to the collection',
        "'s own live market activity. The actions of GOLD collectors are part of this ever-changing artwork, where prices, levels of activity and on-chain provenance define the art itself.\\n\\n",
        "How does the market affect the way we see art? Does the sale price of an NFT change our perception of it? In GOLD, market factors literally influence the appearance of the dynamic imagery. From a sale to a listing, from the amount of time an artwork is held to whether it has recently been flipped, all this data is recorded by the contract and reflected live in each GOLD piece.\\n\\nGOLD is an artistic exploration of NFT market behaviour. It explores how we see in digital environments, and how market networks influence how we see. The full spectrum of possibilities for GOLD will take years to reveal.\\n\\nThe series is 100% on-chain - the artworks are composed and rendered directly from the blockchain - with live data streamed from an Ethereum node. Viewers can change the node by pressing",
        " 'G'.",
        '",',
        '"external_url": "https://making.gold/token/',
        tid,
        '", "image": "',
        baseImageURI,
        tid,
        '.jpg"',
        ', "animation_url":"',
        animationUrl,
        '", "attributes": [',
        getJSONAttributes(generateAllTraits(tokenId)),
        "]}"
      );
  }

  enum VariableType {
    STRING,
    NUMBER
  }

  function constructJsScalarVar(
    VariableType varType,
    string memory name,
    string memory value
  ) internal pure returns (string memory) {
    if (varType == VariableType.STRING) {
      return string(abi.encodePacked("let ", name, ' = "', value, '";'));
    } else if (varType == VariableType.NUMBER) {
      return string(abi.encodePacked("let ", name, " = ", value, ";"));
    } else {
      revert("Invalid varType");
    }
  }

  function getConstantsScript(
    string memory contractAddy,
    string memory contractMetricsSelector,
    string memory tokenMetricsSelector,
    string memory baseTimestamp,
    string memory royaltyPercent,
    string memory tokenId,
    string memory seedToken,
    string memory seedIncrement
  ) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        constructJsScalarVar(VariableType.STRING, "L", contractAddy),
        constructJsScalarVar(VariableType.STRING, "w", contractMetricsSelector),
        constructJsScalarVar(VariableType.STRING, "X", tokenMetricsSelector),
        constructJsScalarVar(VariableType.NUMBER, "$", baseTimestamp),
        constructJsScalarVar(VariableType.NUMBER, "U", royaltyPercent),
        constructJsScalarVar(VariableType.NUMBER, "H", tokenId),
        constructJsScalarVar(VariableType.NUMBER, "g", seedToken),
        constructJsScalarVar(VariableType.NUMBER, "f", seedIncrement)
      );
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    WrappedScriptRequest[] memory requests = new WrappedScriptRequest[](5);

    (uint256 seedToken, uint256 tokenSeedIncrement) = getSeedVariables(tokenId);

    (string memory contractMetricsSelector, string memory tokenMetricsSelector) = goldContract.getSelectors();

    uint256 baseTimestamp = goldContract.baseTimestamp();

    requests[0].name = "crashblossom_gold_base";
    requests[0].wrapType = 0; // <script>[script]</script>
    requests[0].contractAddress = scriptyStorageAddress;

    requests[1].wrapType = 0; // <script>[script]</script>
    requests[1].scriptContent = getConstantsScript(
      Strings.toHexString(address(goldContract)),
      contractMetricsSelector,
      tokenMetricsSelector,
      toString(baseTimestamp),
      toString(royaltyPct),
      toString(tokenId),
      toString(seedToken),
      toString(tokenSeedIncrement)
    );

    requests[2].name = "crashblossom_gold_paths";
    requests[2].wrapType = 2;
    requests[2].contractAddress = scriptyStorageAddress;

    requests[3].name = "gunzipScripts-0.0.1";
    requests[3].wrapType = 0; // <script>[script]</script>
    requests[3].contractAddress = scriptyStorageAddress;

    requests[4].name = "crashblossom_gold_main";
    requests[4].wrapType = 0; // <script>[script]</script>
    requests[4].contractAddress = scriptyStorageAddress;

    bytes memory base64EncodedHTMLDataURI = IScriptyBuilder(scriptyBuilderAddress).getEncodedHTMLWrapped(
      requests,
      bufferSize + requests[1].scriptContent.length + 17 // "<script>".length + "</script>".length = 17
    );

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(getMetadataObject(base64EncodedHTMLDataURI, tokenId))
        )
      );
  }

  function getJSONAttributes(Trait[] memory allTraits) internal pure returns (string memory) {
    string memory attributes;
    uint256 i;
    uint256 length = allTraits.length;
    unchecked {
      do {
        attributes = string(abi.encodePacked(attributes, getJSONTraitItem(allTraits[i], i == length - 1)));
      } while (++i < length);
    }
    return attributes;
  }

  function getJSONTraitItem(Trait memory trait, bool lastItem) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '{"trait_type": "',
          trait.typeName,
          '", "value": "',
          trait.valueName,
          '"}',
          lastItem ? "" : ","
        )
      );
  }

  function nextInt(Seed memory seed) internal pure returns (uint256) {
    seed.current = (1664525 * seed.current + seed.incrementor) % 89652912;
    return seed.current % 101;
  }

  function generateNumberOfColours(Seed memory seed) public view returns (uint256) {
    for (uint256 j = 0; j < 300; j++) {
      for (uint256 i = 0; i < _number_of_colors.length; i++) {
        uint256 r = nextInt(seed);
        if (r > 100 - _number_of_color_chances[i]) {
          return _number_of_colors[i];
        }
      }
    }
    return 2;
  }

  function generateColourNames(
    uint256 numberOfColours,
    Seed memory seed
  ) public view returns (string[] memory) {
    string[] memory selectedColorNames = new string[](numberOfColours);
    for (uint256 i = 0; i < numberOfColours; i++) {
      uint256 while_loop_breaker = 300;
      string memory c;
      while (while_loop_breaker > 0) {
        while_loop_breaker--;

        for (uint256 j = 0; j < color_chance.length; j++) {
          c = color_names[j];
          uint256 r = nextInt(seed);
          if (r > 100 - color_chance[j] && !findElement(selectedColorNames, c)) {
            while_loop_breaker = 0;
            break;
          }
        }
      }
      selectedColorNames[i] = c;
    }

    return selectedColorNames;
  }

  function generateLayerPaths(Seed memory seed) public view returns (string[] memory) {
    string[] memory selected_layer_paths = new string[](24);
    uint8[3] memory types = [0, 1, 2];

    uint256 count = 0;
    for (uint256 j = 0; j < types.length; j++) {
      for (uint256 i = 0; i < 8; i++) {
        uint256[] memory _indexes;
        uint256[] memory _probabilities;
        if (types[j] == 0) {
          if (i == 0) {
            _indexes = layer_1_indexes;
            _probabilities = layer_1_probabilities;
          } else if (i == 1) {
            _indexes = layer_2_indexes;
            _probabilities = layer_2_probabilities;
          } else if (i == 2) {
            _indexes = layer_3_indexes;
            _probabilities = layer_3_probabilities;
          } else if (i == 3) {
            _indexes = layer_4_indexes;
            _probabilities = layer_4_probabilities;
          } else if (i == 4) {
            _indexes = layer_5_indexes;
            _probabilities = layer_5_probabilities;
          } else if (i == 5) {
            _indexes = layer_6_indexes;
            _probabilities = layer_6_probabilities;
          } else if (i == 6) {
            _indexes = layer_7_indexes;
            _probabilities = layer_7_probabilities;
          } else if (i == 7) {
            _indexes = layer_8_indexes;
            _probabilities = layer_8_probabilities;
          }
        } else if (types[j] == 1) {
          _indexes = hodl_layer_indexes;
          _probabilities = hodl_probabilities;
        } else if (types[j] == 2) {
          _indexes = milestone_layer_indexes;
          _probabilities = milestone_probabilities;
        }
        uint256 while_loop_breaker = 300;
        string memory p;
        while (while_loop_breaker > 0) {
          while_loop_breaker--;
          for (uint256 i2 = 0; i2 < _probabilities.length; i2++) {
            uint256 r = nextInt(seed);
            p = paths[_indexes[i2]];
            if (r > 100 - _probabilities[i2] && !findElement(selected_layer_paths, p)) {
              while_loop_breaker = 0;
              break;
            }
          }
        }
        selected_layer_paths[count] = p;
        count++;
      }
    }
    return selected_layer_paths;
  }

  function generateAllTraits(uint256 tokenId) public view returns (Trait[] memory) {
    (uint256 tokenSeed, uint256 tokenSeedIncrement) = getSeedVariables(tokenId);

    uint256 bonusPlateCount = numberOfBonusPlates(tokenId);
    uint256 bonusClusterCount = numberOfBonusClusters();

    Seed memory seed = Seed({current: tokenSeed, incrementor: tokenSeedIncrement});

    uint256 numberOfColours = generateNumberOfColours(seed);
    string[] memory selectedColours = generateColourNames(numberOfColours, seed);
    string[] memory layerPaths = generateLayerPaths(seed);

    Trait[] memory allTraits = new Trait[](
      selectedColours.length + 8 + bonusPlateCount + bonusClusterCount + 1
    );

    uint256 currentIndex = 0;

    allTraits[currentIndex] = Trait({typeName: "Palette Count", valueName: toString(numberOfColours)});

    currentIndex++;

    for (uint256 i = 0; i < 8; i++) {
      allTraits[currentIndex] = Trait({
        typeName: string(
          abi.encodePacked(i % 2 == 0 ? "Gold Plate " : "Gold Cluster ", toString((i / 2) + 1))
        ),
        valueName: layerPaths[i]
      });
      currentIndex++;
    }

    for (uint256 i = 0; i < bonusPlateCount; i++) {
      allTraits[currentIndex] = Trait({
        typeName: string(abi.encodePacked("Bonus Plate ", toString(i + 1))),
        valueName: layerPaths[i + 8]
      });
      currentIndex++;
    }

    for (uint256 i = 0; i < bonusClusterCount; i++) {
      allTraits[currentIndex] = Trait({
        typeName: string(abi.encodePacked("Bonus Cluster ", toString(i + 1))),
        valueName: layerPaths[i + 16]
      });
      currentIndex++;
    }

    for (uint256 i = 0; i < selectedColours.length; i++) {
      allTraits[currentIndex] = Trait({
        typeName: string(abi.encodePacked("Palette ", toString(i + 1))),
        valueName: selectedColours[i]
      });
      currentIndex++;
    }

    return allTraits;
  }

  function stringEq(string memory a, string memory b) internal pure returns (bool result) {
    assembly {
      result := eq(keccak256(add(a, 0x20), mload(a)), keccak256(add(b, 0x20), mload(b)))
    }
  }

  function findElement(string[] memory arr, string memory element) internal pure returns (bool) {
    for (uint256 i = 0; i < arr.length; i++) {
      if (stringEq(arr[i], element)) {
        return true;
      }
    }
    return false;
  }

  function findElement(uint[] memory arr, uint element) internal pure returns (bool) {
    for (uint256 i = 0; i < arr.length; i++) {
      if (arr[i] == element) {
        return true;
      }
    }
    return false;
  }

  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  string[] internal paths = [
    "range",
    "splash",
    "plane",
    "streetlight",
    "glass",
    "left",
    "right",
    "map",
    "fracture",
    "liquid",
    "mosaic",
    "cumulus",
    "recall fragment",
    "pointer",
    "cliff",
    "hill",
    "city",
    "sign",
    "ship",
    "plus",
    "recall flock",
    "bug",
    "honeycomb",
    "ice large",
    "path",
    "footprint small",
    "planet",
    "logo",
    "multiplier",
    "fragment",
    "stratus",
    "flock",
    "river",
    "candle",
    "girder",
    "elevation",
    "urban",
    "plan",
    "floor",
    "ruin",
    "corridor",
    "wall ",
    "pie chart",
    "house",
    "pod",
    "ceiling",
    "window displaced",
    "modern",
    "blueprint",
    "road",
    "bell curve",
    "beam thick",
    "perspective",
    "flame",
    "window pane",
    "window poly",
    "window frame",
    "frame",
    "future",
    "body",
    "beam medium",
    "head",
    "rural",
    "beam thin",
    "ripple",
    "brain",
    "flame high",
    "foothill",
    "mnemonic",
    "jet",
    "mountain",
    "rockies",
    "fingerprint",
    "haze",
    "skeleton",
    "skyline",
    "comic",
    "ribbon",
    "wave",
    "footprint large",
    "ice small"
  ];
  uint256[] internal layer_1_indexes = [11, 34, 35, 2, 37, 38, 39, 40, 41, 43, 14, 23, 36, 3, 42];
  uint256[] internal layer_1_probabilities = [2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 6, 11, 15, 15, 15];
  uint256[] internal layer_2_indexes = [0, 7, 2, 6, 5, 1, 3, 4];
  uint256[] internal layer_2_probabilities = [2, 7, 10, 10, 12, 14, 20, 25];
  uint256[] internal layer_3_indexes = [0, 54, 44, 45, 46, 48, 5, 53, 6, 7, 4, 51, 52, 47, 10, 50, 13, 1, 49];
  uint256[] internal layer_3_probabilities = [2, 2, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 7, 7, 7, 8, 10, 10];
  uint256[] internal layer_4_indexes = [12, 8, 14, 9, 15, 11, 16, 13, 10];
  uint256[] internal layer_4_probabilities = [2, 4, 4, 10, 10, 15, 15, 18, 22];
  uint256[] internal layer_5_indexes = [
    59,
    8,
    55,
    56,
    57,
    9,
    58,
    60,
    15,
    62,
    63,
    16,
    64,
    66,
    19,
    26,
    22,
    61,
    65
  ];
  uint256[] internal layer_5_probabilities = [2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 10, 10, 10, 10, 10];
  uint256[] internal layer_6_indexes = [20, 22, 18, 21, 17, 24, 80, 25, 19];
  uint256[] internal layer_6_probabilities = [2, 4, 5, 5, 8, 10, 15, 25, 26];
  uint256[] internal layer_7_indexes = [
    70,
    30,
    67,
    32,
    17,
    71,
    72,
    24,
    77,
    78,
    69,
    73,
    75,
    74,
    27,
    76,
    79,
    68,
    28
  ];
  uint256[] internal layer_7_probabilities = [2, 2, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 6, 7, 7, 7, 10, 12];
  uint256[] internal layer_8_indexes = [30, 29, 31, 32, 27, 28, 26, 33];
  uint256[] internal layer_8_probabilities = [2, 10, 10, 10, 12, 16, 20, 20];
  uint256[] internal hodl_layer_indexes = [
    6,
    71,
    5,
    7,
    8,
    67,
    17,
    0,
    59,
    24,
    52,
    9,
    64,
    75,
    78,
    15,
    32,
    45,
    1,
    62,
    70,
    69,
    11,
    49,
    4,
    22,
    16,
    73,
    65,
    27,
    76,
    74,
    61,
    68,
    3,
    10,
    13,
    19,
    26,
    28,
    30,
    58
  ];
  uint256[] internal hodl_probabilities = [
    6,
    6,
    7,
    7,
    7,
    7,
    7,
    8,
    8,
    9,
    10,
    10,
    10,
    10,
    10,
    11,
    11,
    12,
    12,
    12,
    12,
    13,
    15,
    15,
    15,
    15,
    15,
    15,
    16,
    16,
    16,
    17,
    18,
    18,
    20,
    20,
    20,
    20,
    20,
    20,
    20,
    25
  ];
  uint256[] internal milestone_layer_indexes = [
    21,
    18,
    14,
    2,
    7,
    0,
    5,
    6,
    8,
    9,
    15,
    17,
    24,
    27,
    32,
    1,
    4,
    11,
    16,
    22,
    3,
    10,
    13,
    19,
    26,
    28,
    30,
    31,
    29,
    33
  ];
  uint256[] internal milestone_probabilities = [
    3,
    4,
    5,
    7,
    7,
    8,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    12,
    15,
    15,
    15,
    15,
    20,
    20,
    20,
    20,
    20,
    20,
    20,
    20,
    25,
    27
  ];

  // number of color chances

  uint256[] internal _number_of_colors = [1, 8, 16, 4, 2, 3];
  uint256[] internal _number_of_color_chances = [5, 5, 5, 10, 20, 50];

  // The names of all color schemes
  string[] internal color_names = [
    "rhodium",
    "palladium",
    "vegas",
    "platinum",
    "ipanema",
    "malibu",
    "venicebeach",
    "cannes",
    "maldives",
    "dusk",
    "sunset",
    "mist",
    "southbeach",
    "night",
    "ibiza",
    "dawn",
    "goldenhour"
  ];
  uint256[] internal color_chance = [3, 4, 4, 5, 5, 5, 5, 5, 6, 7, 7, 8, 10, 12, 20, 30, 40];
}