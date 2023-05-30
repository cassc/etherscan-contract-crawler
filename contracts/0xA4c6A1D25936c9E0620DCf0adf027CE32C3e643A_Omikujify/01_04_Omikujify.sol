// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


/** @title Omikujify Contract
  * @author @0xAnimist
  * @notice First Onchain GIF, collaboration between Cai Guo-Qiang and Kanon
  */
contract Omikujify {
  bool public _freeze;

  uint256 constant baseWidth = 384;
  uint256 constant baseHeight = 860;
  uint256 constant seedWidth = 434;
  uint256 constant seedHeight = 770;
  uint256 constant poemHeight = 255;
  uint256 constant twoPivotsHeight = 150;
  uint256 constant fontSize = 12;
  string constant _defs = '<defs><style><![CDATA[ .lines {stroke: white; stroke-width: 1;} .green {fill: #35A98E;} .violet {fill: #5F5FBC;} .white {fill: #FFFFFF} .grey {fill: #BDBDBD;} .mono {font-family:Monaco, monospace; font-size:10px;} .centered {text-anchor: middle;} .heading {font-family: "Times New Roman"; font-style:normal;font-weight:400;font-size:21px;letter-spacing: 0.03em;text-transform:uppercase;} .copy {font-size:18px;text-align: center;} .img {opacity:0.35;} ]]></style><pattern id="dot" viewBox="0,0,48,48" width="16.5%" height="7.692%"><circle cx="0" cy="1" r="1" fill="#ffffff" /></pattern><linearGradient id="topfade" x1="0" x2="0" y1="0"  y2="1"><stop offset="0%" stop-color="black" stop-opacity="0.75"/><stop offset="30%" stop-color="black" stop-opacity="0.35"/><stop offset="100%" stop-color="black" stop-opacity="0"/></linearGradient><linearGradient id="bottomfade" x1="0" x2="0" y1="0"  y2="1"><stop offset="0%" stop-color="black" stop-opacity="0"/><stop offset="30%" stop-color="black" stop-opacity="0.35"/><stop offset="100%" stop-color="black" stop-opacity="0.75"/></linearGradient></defs>';

  string constant _bg = '<rect x="0" y="0" width="100%" height="100%" fill="black" />';

  string constant _grid = '<rect x="48" y="169" width="290" height="576" fill="url(#dot)" /></svg>';

  string constant _numbers = '<svg class="mono white" x="47" y="115"><text y="10">0</text><text y="10" x="48">1</text><text y="10" x="96">2</text><text y="10" x="144">3</text><text y="10" x="192">4</text><text y="10" x="240">5</text><text y="10" x="288">6</text><text y="634">0</text><text y="634" x="48">1</text><text y="634" x="96">2</text><text y="634" x="144">3</text><text y="634" x="192">4</text><text y="634" x="240">5</text><text y="634" x="288">6</text></svg>';

  string constant _numbersGrey = '<svg class="mono grey" x="47" y="115"><text y="10">0</text><text y="10" x="48">1</text><text y="10" x="96">2</text><text y="10" x="144">3</text><text y="10" x="192">4</text><text y="10" x="240">5</text><text y="10" x="288">6</text><text y="634">0</text><text y="634" x="48">1</text><text y="634" x="96">2</text><text y="634" x="144">3</text><text y="634" x="192">4</text><text y="634" x="240">5</text><text y="634" x="288">6</text></svg>';

  string constant _changeLine = '<line x1="0" y1="20" x2="40" y2="20" stroke="white" stroke-opacity="0.5"/><line x1="20" y1="0" x2="20" y2="40" stroke="white" stroke-opacity="0.5"/><circle cx="20" cy="20" r="3" fill="white" fill-opacity="1.0"/>';

  string[] public _changeLineXvalues = ["78","125","173","221","269","317"];
  string[] public _changeLineYvalues = ["140","195","239","283","327","372","416","460","504","549","593","638","682"];


  constructor() { }


  function getHeight(uint256[] memory _pivots) public pure returns(uint256 hh) {
    hh = baseHeight + poemHeight;

    if(_pivots.length > 0){
      hh += poemHeight;
    }

    hh += (_pivots.length % 2) * twoPivotsHeight;
  }

  function formatSVG(string memory _seedGif, string memory _eetGif, string memory _forkGif, string[] memory _metadataArray) public view returns(string memory) {
    string memory hh = Strings.toString(baseHeight);
    //uint256 xx = (baseHeight - baseWidth) / 2;//left offset if 1:1 aspect ratio
    string memory ww = Strings.toString(baseWidth);

    string memory header = string(abi.encodePacked(
      '<svg version="1.1" width="',
      ww,
      '" height="',
      hh,
      '" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
      _defs
    ));

    string memory image = string(abi.encodePacked(
      '<svg width="100%" height="100%" x="0" y="0"><filter id="dither" x="0" y="0"><feTurbulence type="fractalNoise" baseFrequency="0.7" stitchTiles="stitch"/></filter><rect width="100%" height="100%" filter="url(#dither)" opacity="0.2"/><image class="img" preserveAspectRatio="none" x="-25" y="-25" width="434" height="910" xlink:href="data:image/gif;base64,',
      _seedGif,
      '"/><rect x="0" y="0" width="100%" height="30%" fill="url(#topfade)"/><rect x="0" y="70%" width="100%" height="30%" fill="url(#bottomfade)"/>',
      '<image preserveAspectRatio="none" x="-22" y="100" width="430" height="671" xlink:href="data:image/gif;base64,',
      _eetGif,
      '"/><image preserveAspectRatio="none" x="-22" y="100" width="430" height="671" xlink:href="data:image/gif;base64,',
      _forkGif,
      '"/></svg>'
    ));

    //string memory _svgHeader = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 438 1200" style="enable-background:new 0 0 100 100;" xml:space="preserve">';

    string memory headerFooter = string(abi.encodePacked(
      '<svg x="0" y="0" width="100%" height="100%"><text class="heading green centered" y="59" x="50%">',
      _metadataArray[1],
      '</text><text class="mono white centered" y="77" x="50%">FORTUNE</text><text class="mono white centered" y="797" x="50%">FORK</text><text class="heading violet centered" y="821" x="50%">',
      _metadataArray[2],
      '</text></svg>'
    ));

    string memory svg = string(abi.encodePacked(
      header,
      _bg,
      '<svg width="100%" height="100%" y="0" x="0">',
      image,
      headerFooter,
      _numbers,
      _grid
    ));

    svg = string(abi.encodePacked(
      svg,
      _changeLines(_metadataArray[3], _metadataArray[4]),
      '</svg>'
    ));

    string memory metadata = string(abi.encodePacked(
      _metadataArray[0],
      '"image": "data:image/svg+xml;base64,'
    ));

    metadata = string(abi.encodePacked(
      metadata,
      Base64.encode(bytes(svg)),
      '"}'
    ));

    return string(abi.encodePacked(
      'data:application/json;base64,',
      Base64.encode(bytes(metadata))
    ));
  }

  function _changeLines(string memory _binomialFortuneAsString, string memory _binomialShiftsAsString) internal view returns(string memory) {
    string memory changes;
    uint256 path = 6;

    for(uint256 i = 0; i < 6; i++){
      if(_isOneAtIndex(_binomialFortuneAsString, i)){
        path--;
      }else{
        path++;
      }

      if(_isOneAtIndex(_binomialShiftsAsString, i)){
        changes = string(abi.encodePacked(
          changes,
          '<svg opacity="0" x="',
          _changeLineXvalues[i],
          '" y="',
          _changeLineYvalues[path],
          '" width="40" height="40">',
          _changeLine
        ));

        changes = string(abi.encodePacked(
          changes,
          '<animate attributeName="opacity" dur="0.5s" values="0;1" begin="',
          Strings.toString(i+1),
          's" fill="freeze" stroke="freeze"/>',
          '</svg>'
        ));
      }
    }

    return changes;
  }

  function _isOneAtIndex(string memory str, uint256 index) internal pure returns (bool) {
    bytes memory bytesStr = bytes(str);

    // Make sure the index is within the bounds of the string
    if (index >= bytesStr.length) {
        return false;
    }

    // Extract the character at the given index
    bytes1 character = bytesStr[index];

    // Compare the character to '1'
    return (character == '1');
  }



  function formatVirgin(string memory _metadataHeader) public pure returns(string memory) {
    string memory hh = Strings.toString(baseHeight);
    string memory ww = Strings.toString(baseWidth);

    string memory header = string(abi.encodePacked(
      '<svg version="1.1" width="',
      ww,
      '" height="',
      hh,
      '" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
      _defs
    ));

    string memory headings = string(abi.encodePacked(
      '<svg x="0" y="0" width="100%" height="100%"><text class="mono grey centered" y="55" x="50%">EET</text><text class="mono grey centered" y="69" x="50%">BY CAI GUO-QIANG x KANON</text><text class="mono grey centered" y="803" x="50%">REDEEMABLE FOR</text><text class="mono grey centered" y="817" x="50%">ONE EET FORTUNE</text></svg>'
    ));

    string memory svg = string(abi.encodePacked(
      header,
      _bg,
      '<svg width="100%" height="100%" y="0" x="0">',
      headings,
      _numbersGrey,
      _grid,
      '</svg>'
    ));

    string memory metadata = string(abi.encodePacked(
      _metadataHeader,
      '"image": "data:image/svg+xml;base64,'
    ));

    metadata = string(abi.encodePacked(
      metadata,
      Base64.encode(bytes(svg)),
      '"}'
    ));

    return string(abi.encodePacked(
      'data:application/json;base64,',
      Base64.encode(bytes(metadata))
    ));
  }



}//end Omikujify