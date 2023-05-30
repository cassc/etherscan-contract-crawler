// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./Base64.sol";
import "./iGUA.sol";
import "./GUA.sol";
import "./BytesLib.sol";
import "./GIF89a.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";


interface iOmikujify {
  function formatSVG(string memory _seedGif, string memory _eetGif, string memory _forkGif, string[] memory _metadataArray) external view returns(string memory);
  function formatVirgin(string memory _slug) external view returns(string memory);
}

interface iBiChing {
  function cast(bytes memory _input) external pure returns(uint8[] memory fortune, uint8[] memory fork, uint8 forkcount);
  function getBinomialPathsAsStrings(uint8[] memory _fortune, uint8[] memory _fork) external pure returns(string memory fortuneBinomial, string memory forkBinomial);
  function fortuneIndex(uint8[] memory _fortune) external pure returns(uint256 index);
  function forkIndex(uint8[] memory _fortune, uint8[] memory _fork) external pure returns(uint256 index);
}

interface iScoreBoard {
  function getMintPayload(uint256 _eetTokenId) external view returns(bytes memory);
  function getBurnPayload(uint256 _eetTokenId) external view returns(bytes memory);
}

interface iFortuneRouter {
  function getMetadataHeader(uint256 _index) external view returns (string memory);
  function getName(uint256 _index) external view returns (string memory);
}

interface iEETRenderEngine {
  function render(
    uint256 _tokenId,
    address _guaContract,
    bytes3[] memory _colors,
    bytes memory _packedHeader
  ) external returns (string memory);
}


/** @title EETRenderEngine Contract
  * @author @0xAnimist
  * @notice First Onchain GIF, collaboration between Cai Guo-Qiang and Kanon
  */
contract EETRenderEngine is Ownable {
  uint256 public _version;
  uint256[] public _versionMaxId;
  address[] public _renderers;//indexed by _version
  uint8 public constant _blankIndex = 0;
  uint8 public constant _fortuneIndex = 1;
  uint8 public constant _forkIndex = 2;
  bytes1 public constant _transIndex = 0x00;
  address public _omikujify;
  address public _biChing;
  bool public _frozen;
  address public _fortuneRouter;
  address public _eet;
  bool public _eetFrozen;


  constructor(address omikujify_, address biChing_, address fortuneRouter_) Ownable() {
    _omikujify = omikujify_;
    _biChing = biChing_;
    _fortuneRouter = fortuneRouter_;
    _renderers.push(address(this));
  }

  function setEET(address eet_) external onlyOwner {
    require(!_eetFrozen, "frozen");
    _eet = eet_;
    _eetFrozen = true;
  }

  function incrementVersion(address _newRenderer) external onlyOwner {
    require(_eetFrozen, "must freeze EET contract");
    _versionMaxId.push(IERC721Enumerable(_eet).totalSupply());//EET starts at id = 1
    _version++;
    _renderers.push(_newRenderer);
  }

  function setDependencies(address omikujify_, address biChing_, address fortuneRouter_, bool freeze_) public onlyOwner {
    require(!_frozen, "frozen");
    _omikujify = omikujify_;
    _biChing = biChing_;
    _fortuneRouter = fortuneRouter_;
    _frozen = freeze_;
  }

  /*TODO: remove events and make function view*/
  function render(
    uint256 _tokenId,
    address _guaContract,
    bytes3[] memory _colors,
    bytes memory _packedHeader
  ) public returns (string memory) {
    require(_eetFrozen, "must freeze EET contract");
    if(_version > 0 && _versionMaxId[0] < _tokenId){
      uint256 v = 1;
      for(uint256 i = 1; i < _version; i++){
        if(_versionMaxId[i] < _tokenId){
          v++;
        }
      }
      return iEETRenderEngine(_renderers[v]).render(_tokenId, _guaContract, _colors, _packedHeader);
    }else{
      bytes memory gif;
      bytes32 seed;
      bool queried;
      uint8 colorIndex;
      bytes2 bitstream;

      (seed,,,,gif,,,queried,colorIndex,bitstream) = _parseGuas(_guaContract, _tokenId);

      string memory GUAColorAttributes = string(abi.encodePacked(
        '{"trait_type": "GUAcolor", "display_type": "number", "value": ',
        Strings.toString(uint256(colorIndex)),
        '}, {"trait_type": "GUAbitstream", "display_type": "number", "value": ',
        Strings.toString(uint256(uint16(bitstream))),
        '}, '
      ));

      if(queried){
        return _renderQueried(_colors, _packedHeader, gif, seed, GUAColorAttributes);
      }else{
        return _renderVirgin();
      }
    }
  }

  function _parseGuas(address _guaContract, uint256 _tokenId) internal view returns(
    bytes32 seed,//hash of query, randomness, & context
    bytes32 queryhash,//hash of query alone
    uint256 timestamp,
    uint256 rand,
    bytes memory gif,
    string memory encrypted,
    string memory query,//blank unless published
    bool queried,//false if gifted
    uint8 colorIndex,
    bytes2 bitstream
  ){
    return GUA(_guaContract)._guas(_tokenId);
  }

  //returns binomialFortune and binomialShifts as attribute string
  function _pathAttributes(
    uint256 _tokenId,
    address _guaContract,
    bytes3[] memory _colors,
    bytes memory _packedHeader
  ) internal view returns(string memory binomialFortune, string memory binomialShifts, string memory fortuneGif, string memory forkGif) {
    (, bytes32 seed, bool queried,) = iGUA(_guaContract).getData(_tokenId);

    if(queried){
      uint8[] memory fortune;
      uint8[] memory fork;
      (fortune, fork, fortuneGif, forkGif) = _cast(_colors, _packedHeader, seed);

      (binomialFortune, binomialShifts) = iBiChing(_biChing).getBinomialPathsAsStrings(fortune, fork);
    }
  }


  function api(
    uint256 _tokenId,
    address _guaContract,
    bytes3[] memory _colors,
    bytes memory _packedHeader,
    address _scoreBoardAddress
  ) public view returns (string memory json) {
    (string memory binomialFortune, string memory binomialShifts, string memory fortuneGif, string memory forkGif) = _pathAttributes(_tokenId, _guaContract, _colors, _packedHeader);

    json = string(abi.encodePacked(
      '{"EET": {"tokenId": ',
      Strings.toString(_tokenId),
      ', "binomialFortune": "',
      binomialFortune,
      '", "binomialShifts": "',
      binomialShifts
    ));

    json = string(abi.encodePacked(
      json,
      '", "fortuneGif": "',
      fortuneGif,
      '", "forkGif": "',
      forkGif,
      '"},'
    ));


    //append GUA API data
    json = string(abi.encodePacked(
      json,
      '"GUA": ',
      iGUA(_guaContract).tokenAPI(_tokenId)
    ));

    return _appendPayloads(_tokenId, _scoreBoardAddress, json);

  }

  function _appendPayloads(uint256 _tokenId, address _scoreBoardAddress, string memory _json) internal view returns(string memory json){
    json = string(abi.encodePacked(
      _json,
      ', "scoreboard": {',
      '"mintPayload": "',
      BytesLib.toHex(iScoreBoard(_scoreBoardAddress).getMintPayload(_tokenId)),
      '", "burnPayload": "',
      BytesLib.toHex(iScoreBoard(_scoreBoardAddress).getBurnPayload(_tokenId)),
      '"}}'
    ));
  }

  function _cast(
    bytes3[] memory _colors,
    bytes memory _packedHeader,
    bytes32 _seed
  ) internal view returns (uint8[] memory fortune, uint8[] memory fork, string memory fortuneGif, string memory forkGif) {
    //GENERATE PIXELS
    bytes[] memory pixels = new bytes[](3);
    pixels = generatePixels(_colors);

    //CAST THE BICHING
    uint8 forkcount;
    (fortune, fork, forkcount) = iBiChing(_biChing).cast(abi.encodePacked(_seed));

    //FORTUNE
    fortuneGif = _assembleAnimated(_fortuneIndex, pixels, fortune, 7, _packedHeader);

    //FORK
    forkGif = _assembleAnimated(_forkIndex, pixels, fork, forkcount, _packedHeader);
  }

  function _renderQueried(
    bytes3[] memory _colors,
    bytes memory _packedHeader,
    bytes memory _gif,
    bytes32 _seed,
    string memory _colorAttributes
  ) internal view returns (string memory) {
    string memory seedGif = Base64.encode(_gif);

    //CAST THE BICHING
    (uint8[] memory fortune, uint8[] memory fork, string memory fortuneGif, string memory forkGif) = _cast(_colors, _packedHeader, _seed);

    uint256 fortuneIndex = iBiChing(_biChing).fortuneIndex(fortune);
    uint256 forkIndex = iBiChing(_biChing).forkIndex(fortune, fork);

    string memory fortuneName = iFortuneRouter(_fortuneRouter).getName(fortuneIndex);
    string memory forkName = forkIndex == fortuneIndex ? "/" : iFortuneRouter(_fortuneRouter).getName(forkIndex);
    string memory metadataHeader = iFortuneRouter(_fortuneRouter).getMetadataHeader(fortuneIndex);

    (string memory binomialFortune, string memory binomialShifts) = iBiChing(_biChing).getBinomialPathsAsStrings(fortune, fork);

    string memory binomialAttributes = '{"trait_type": "binomialFortune", "value": "';
    binomialAttributes = string(abi.encodePacked(
      binomialAttributes,
      binomialFortune,
      '"}, {"trait_type": "binomialShifts", "value": "',
      binomialShifts,
      '"}], '
    ));

    metadataHeader = string(abi.encodePacked(metadataHeader, _colorAttributes, binomialAttributes));

    string[] memory metadata = new string[](5);
    metadata[0] = metadataHeader;
    metadata[1] = fortuneName;
    metadata[2] = forkName;
    metadata[3] = binomialFortune;
    metadata[4] = binomialShifts;

    return iOmikujify(_omikujify).formatSVG(seedGif, fortuneGif, forkGif, metadata);
  }

  function _renderVirgin() internal view returns (string memory) {
    string memory slug = '{"name": "EET Voucher", "description": "Redeemable for one EET Fortune", "attributes": [{"trait_type": "revealed", "value": "false"}], ';
    return iOmikujify(_omikujify).formatVirgin(slug);
  }

  function generatePixels(bytes3[] memory _colors) public pure returns (bytes[] memory pixels) {
    //Generate pixels
    pixels = new bytes[](3);

    uint8[][] memory tempPixel = new uint8[][](3);
    for(uint8 i = 0; i < 3; i++){
      tempPixel[i] = new uint8[](3);
    }

    uint16 _minCodeSize = uint16(GIF89a.root2(GIF89a.fullColorTableSize(_colors.length)));

    pixels[_blankIndex] = GIF89a.formatImageLZW(tempPixel, _minCodeSize);

    tempPixel[1][1] = _fortuneIndex;
    pixels[_fortuneIndex] = GIF89a.formatImageLZW(tempPixel, _minCodeSize);

    tempPixel[1][1] = _forkIndex;
    pixels[_forkIndex] = GIF89a.formatImageLZW(tempPixel, _minCodeSize);
  }

  function _assembleAnimated(uint8 _pixelIndex, bytes[] memory _pixels, uint8[] memory _y, uint8 _pixelcount, bytes memory _packedHeader) internal pure returns (string memory gif) {
    bytes memory buffer;
    uint8 len = 7;
    uint8 startIndex = len - _pixelcount;

    bytes memory gce = GIF89a.formatGCE(true, 0x04, 0x6400, true, _transIndex);//1s delay
    //apply a longer delay to the final frame
    bytes memory gceLast = GIF89a.formatGCE(true, 0x04, 0x5E01, true, _transIndex);//3.5s delay = )x5E01

    for(uint8 i = 0; i < len; i++){
      //image descriptor
      bytes memory imgDesc = GIF89a.formatImageDescriptor(i, _y[i], 3, 3, 0x0000);

      //pixel-specific metadata
      if(i == 0){//if first iteration
        buffer = BytesLib.concat(_packedHeader, imgDesc);
      }else{
        if(i == (len-1)){
          buffer = BytesLib.concat(buffer, BytesLib.concat(gceLast, imgDesc));
        }else{
          buffer = BytesLib.concat(buffer, BytesLib.concat(gce, imgDesc));
        }
      }

      //lzw image data
      if(i >= startIndex){
        buffer = BytesLib.concat(buffer, _pixels[_pixelIndex]);
      }else{
        buffer = BytesLib.concat(buffer, _pixels[_blankIndex]);
      }
    }//end for

    //trailer
    buffer = BytesLib.concat(buffer, GIF89a.formatTrailer());

    gif = Base64.encode(buffer);
  }


}//end EETRenderEngine