// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IRenderer {
  function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}

contract Renderer  {

  using Strings for uint256;

  struct GeneratorConfig {
    uint head;
    uint layerOne;
    uint layerTwo;
    uint layerThree;
    uint layerOneColor;
    uint layerTwoColor;
    uint layerThreeColor;
    uint headColor;
    bool isUnicolor;
    bool isSpecialHead;
    uint specialHead;
    bool hasTitle;
    uint titleColor;
    uint title;
    bool hasDecoration;
    uint decoration;
    uint decorationColor;
    bool hasConsistency;
  }

  enum RANDPOS{ TITLE, HEAD, LAYER_ONE, LAYER_TWO, LAYER_THREE, HEAD_COLOR, LAYER_ONE_COLOR, LAYER_TWO_COLOR, LAYER_THREE_COLOR, SPECIAL_HEAD, SPECIAL_HEAD_COLOR, TITLE_COLOR, DECORATION, DECORATION_COLOR }

  string[][] colors = [
  ["#e60049", "UA Red"],
  ["#82b6b9", "Pewter Blue"],
  ["#b3d4ff", "Pale Blue"],
  ["#00ffff", "Aqua"],
  ["#0bb4ff", "Blue Bolt"],
  ["#1853ff", "Blue RYB"],
  ["#35d435", "Lime Green"],
  ["#61ff75", "Screamin Green"],
  ["#00bfa0", "Caribbean Green"],
  ["#ffa300", "Orange"],
  ["#fd7f6f", "Coral Reef"],
  ["#d0f400", "Volt"],
  ["#9b19f5", "Purple X11"],
  ["#dc0ab4", "Deep Magenta"],
  ["#f46a9b", "Cyclamen"],
  ["#bd7ebe", "African Violet"],
  ["#fdcce5", "Classic Rose"],
  ["#FCE74C", "Gargoyle Gas"],
  ["#eeeeee", "Bright Gray"],
  ["#7f766d", "Sonic Silver"]
];

  string[][] specialHeads = [
[
    ')',
    ') \\',
    ' / ) (',
    '\\(_)/'
],
[
    '',
    'P~O~O~O~P',
    '\\|/',
    '    _^_    '
],
[
    '',
    '*  *  *',
    '\\|/',
    '    _^_    '
],
[
    '',
    '                        /)               ',
    '                    -:))  BzzzBzBzzzz ',
    '                   _^_  \\)               '
]
  ];

  string[7] heads = [
      unicode"    _꒰_    ", "    _#_    ", " _o_ ", " _ ", "  _$_  ", unicode"  _♢_  ", unicode"    _ヘ_    "
  ];
  string[7] layerThrees = [
      " (___) ", " {__#} ", " (OoO) ", " [___] ", " ($_$) ", unicode" (♢♢♢) ", " (___) "
  ];
  string[7] layerTwos = [
      " (_____) ", " {__#__} ", " (oOo0O) ", " [_____] ", " ($_$_$) ", unicode" (♢♢♢♢♢) ", " (_____) "
  ];
  string[7] layerOnes = [
      " (_______) ", " {_____#_} ", " (OOooOO0) ", " [_______] ", " ($_$_$_$) ", unicode" (♢♢♢♢♢♢♢) ", " (C_O_I_N) "
  ];

  string[7] titles = [
    "SOLID",
    "OLD",
    "FRACTIONALIZED",
    "HARD",
    "MICHELIN",
    "DIAMOND",
    "SHITCOIN"
  ];

  string[] decorations = ['#','**', unicode'°´´', '....', '~~'];

  function getPos(RANDPOS pos) public pure returns (uint8) {
    return uint8(pos);
  }

  function tokenURI(uint256 tokenId, uint256 seed) public view returns (string memory) {

    GeneratorConfig memory config = getGeneratorConfig(seed);
    
    string memory description = "Turds on-chain";

    bytes memory json = bytes (
      abi.encodePacked(
          '{',
          '"name":"OnChainTurds #', tokenId.toString(), '",',
          '"description":"', description, '",',
          '"image": "', getSvg(config), '",',
          '"attributes": ', getAttributesJson(config),
          '}'
        )
    );
    string memory base64Json = Base64.encode(bytes(json));
    
    return string(abi.encodePacked("data:application/json;base64,", base64Json));
  }

  function getAttributesJson(GeneratorConfig memory config) internal view returns (string memory) {
    string[4] memory specialHeadnames = [
      "HotPot",
      "Poop",
      "Rocket",
      "Fly"
    ];
    string[5] memory smell = ['Very Strong','Strong', 'Max Fear', 'Noticeable', 'Dominant'];
    string[8] memory trait_types = [
        "Head",
        "L1", 
        "L2", 
        "L3",
        "Smell",
        "Consistency",
        "Grade",
        "Color"
      ];
      string memory l1c = colors[config.layerOneColor][1];
      string memory l2c = colors[config.layerTwoColor][1];
      string memory l3c = colors[config.layerThreeColor][1];

      string[8] memory trait_values = [
        config.isSpecialHead ? specialHeadnames[config.specialHead] : titles[config.head],
        string(abi.encodePacked(config.hasConsistency ? titles[config.layerThree] : titles[config.layerOne], ' (', l1c, ')')),
        string(abi.encodePacked(config.hasConsistency ? titles[config.layerThree] : titles[config.layerTwo], ' (', l2c, ')')),
        string(abi.encodePacked(titles[config.layerThree], ' (', l3c, ')')),
        config.hasDecoration ? smell[config.decoration] : "None",
        config.hasConsistency ? titles[config.layerThree] : "Inconsistent",
        config.hasTitle ? titles[config.title] : "None",
        config.isUnicolor ? "Uniform" : "Multicolor"
      ];
      uint8 trait_count = uint8(trait_types.length);
      string memory attributes = '[\n';
      for (uint8 i = 0; i < trait_count; i++) {
        attributes = string(abi.encodePacked(attributes,
          (i > 0) ? ',' : '', '{"trait_type": "', trait_types[i], '", "value": "', trait_values[i],'"}','\n'
        ));
      }
      return string(abi.encodePacked(attributes, ']'));
    }

  function getVal(uint256 num, RANDPOS _pos) public view returns (uint8) {
    uint8 pos = uint8(_pos);
    return uint8((num & (255 << (8 * pos))) >> (8 * pos));
  }

  function joinStr(string[] memory strings) public view returns (string memory) {
    string memory result = "";
    for (uint i = 0; i < strings.length; i++) {
      result = string(abi.encodePacked(result, strings[i]));
    }
    return result;
  }

  function getGeneratorConfig(uint seed) private view returns (GeneratorConfig memory) {
    bool hasConsistency = getRand(seed, 100, "consistency") < 42;
    GeneratorConfig memory config = GeneratorConfig({
      head: getVal(seed, RANDPOS.HEAD) % heads.length,
      layerThree: getVal(seed, RANDPOS.LAYER_THREE) % layerThrees.length,
      layerTwo: getVal(seed, RANDPOS.LAYER_TWO) % layerTwos.length,
      layerOne: getVal(seed, RANDPOS.LAYER_ONE) % layerOnes.length,
      layerThreeColor: getVal(seed, RANDPOS.LAYER_THREE_COLOR) % colors.length,
      layerTwoColor: getVal(seed, RANDPOS.LAYER_TWO_COLOR) % colors.length,
      layerOneColor: getVal(seed, RANDPOS.LAYER_ONE_COLOR) % colors.length,
      headColor: getVal(seed, RANDPOS.HEAD_COLOR) % colors.length,
      isUnicolor: getRand(seed, 100, "ucolor") < 15,
      isSpecialHead: getRand(seed, 100, "shithead") < 10, // 10
      specialHead: getVal(seed, RANDPOS.SPECIAL_HEAD) % specialHeads.length,
      hasTitle: hasConsistency && getRand(seed, 100, "title") < 10,
      titleColor: getVal(seed, RANDPOS.TITLE_COLOR) % colors.length,
      title: getVal(seed, RANDPOS.TITLE) % titles.length,
      hasDecoration: getRand(seed, 100, "dec") < 35,
      decoration: getVal(seed, RANDPOS.DECORATION) % decorations.length,
      decorationColor: getVal(seed, RANDPOS.DECORATION_COLOR) % colors.length,
      hasConsistency: hasConsistency
    });
    return config;
  }

  function getLayers(GeneratorConfig memory config) private view returns (string memory) {
    string memory layerThree = layerThrees[config.layerThree];
    string memory layerTwo = config.hasConsistency ? layerTwos[config.layerThree] : layerTwos[config.layerTwo];
    string memory layerOne = config.hasConsistency ? layerOnes[config.layerThree] : layerOnes[config.layerOne];
    string memory l3c = colors[config.layerThreeColor][0];
    string memory l2c = config.isUnicolor ? l3c : colors[config.layerTwoColor][0];
    string memory l1c = config.isUnicolor ? l3c : colors[config.layerOneColor][0];
    string memory layers = string(abi.encodePacked(
      '<tspan dy="30" x="160" fill="',l3c,'" xml:space="preserve">',layerThree,'</tspan>',
      '<tspan dy="30" x="160" fill="',l2c,'" xml:space="preserve">',layerTwo,'</tspan>',
      '<tspan dy="30" x="160" fill="',l1c,'" xml:space="preserve">',layerOne,'</tspan>'
    ));
    return layers;
  }

  function getDecorations(GeneratorConfig memory config) private view returns (string memory) {
    if(!config.hasDecoration) return "";
    string memory decoration = decorations[config.decoration];
    string memory _decorations = string(abi.encodePacked(
    '<text style="font-size:12pt;" x="70" transform="rotate(40 160 160)">',
      '<tspan y="190" fill="red">',decoration,'</tspan>',
      '<tspan y="190" dy="20" fill="red">',decoration,'</tspan>',
    '</text>',
    '<text style="font-size:12pt;" x="200" transform="rotate(-40 160 160)">',
      '<tspan y="190" dy="20" fill="red">',decoration,'</tspan>',
      '<tspan y="190"  fill="red">',decoration,'</tspan>'
    '</text>'
    ));

    return _decorations;
  }

  function getTitle(GeneratorConfig memory config) private view returns (string memory) {
    if(!config.hasTitle) return "";
    string memory title = titles[config.title];
    return string(
      abi.encodePacked(
        '<tspan dy="15" x="160" font-family="arial" fill="',colors[config.titleColor][0],'" xml:space="preserve">',title,'</tspan>'
      )
    );
  }

  function getHead(GeneratorConfig memory config) private view returns (string memory) {
    string memory headColor = config.isUnicolor ? colors[config.layerThreeColor][0] : colors[config.headColor][0];
    string memory head = heads[config.head];

    string memory specialHead = "";
    string memory specialHeadColor = config.specialHead == 0 ? "red" : headColor;
    if(config.isSpecialHead) {
      string[] memory _specialHead = new string[](4);
      string[] storage selectedHead = specialHeads[config.specialHead];
      for (uint256 index = 0; index < 4; index++) {
        string memory s = string(abi.encodePacked('<tspan dy="20" x="160" fill="',specialHeadColor,'" xml:space="preserve">',selectedHead[index],'</tspan>'));
        _specialHead[index] = s;
      }
      //  '<animate attributeName="fill" values="red;blue;red" dur="5s" repeatCount="indefinite" />',
      specialHead = joinStr(_specialHead);
    }

    return config.isSpecialHead 
    ? string(abi.encodePacked(
       specialHead
    ))
    : string(abi.encodePacked(
       '<tspan dy="50" x="160" fill="',headColor,'" xml:space="preserve">',head,'</tspan>'
    ));
  }

  function getRand(uint256 seed, uint scale, string memory noise) private view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(seed, noise))) % scale;
  }

  function getSvg(GeneratorConfig memory config) private view returns (string memory) {
    
    uint size = 320;

    string memory svgStr = string(abi.encodePacked(
    '<svg xmlns="http://www.w3.org/2000/svg" width="',size.toString(),'" height="',size.toString(),'" viewBox="0 0 ',size.toString(),' ',size.toString(),'">',
    '<rect width="100%" height="100%" fill="#121212">',
    '</rect>',
    '<text x="160" y="50" font-family="Menlo,monospace" font-weight="700" font-size="20" text-anchor="middle" letter-spacing="1">',
      getTitle(config),
      getHead(config),
      getLayers(config),
    '</text>',
    getDecorations(config),
    '</svg>'
    ));

    bytes memory svg = bytes(svgStr);
    string memory svgBase64 = Base64.encode(bytes(svg));
    return string(abi.encodePacked("data:image/svg+xml;base64,", svgBase64));
  }

}