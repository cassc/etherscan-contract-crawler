// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./iGUA.sol";
import "./GUA.sol";
import "./BytesLib.sol";
import "./Base64.sol";
//import "./Trig.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";


/** @title GUAMetadata Contract
  * @author @0xAnimist
  * @notice First Onchain GIF, collaboration between Cai Guo-Qiang and Kanon
  */
contract FetusMovement is Ownable {
  address public _guaContract;
  bool public _freeze;
  uint256 public _totalSnapshots;
  uint256 public ww = 27;
  uint256 public hh = 270;
  uint256 public _maxCircleParts = 16384;
  uint256 public _maxSine = 32767;

  mapping(uint256 => bytes) public _snapshots;

  struct Point {
    uint8 left;
    uint8 top;
  }

  constructor () Ownable() {}

  function setGuaContract(address guaContract_, bool freeze_) external onlyOwner {
    require(!_freeze, "frozen");
    _guaContract = guaContract_;
    _freeze = freeze_;
  }

  function getGuaContract() external view returns(address){
    return _guaContract;
  }

  function snap() external {
    _snapshots[_totalSnapshots] = getGif();
    _totalSnapshots++;
  }

  function getSnapshot(uint256 _index) external view returns(bytes memory){
    return _snapshots[_index];
  }

  function getAllSnapshots() external view returns(bytes[] memory snapshots){
    snapshots = new bytes[](_totalSnapshots);
    for(uint256 i = 0; i < _totalSnapshots; i++){
      snapshots[i] = _snapshots[i];
    }
  }

  function _parseGuas(uint256 _i) internal view returns(
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
    require(_freeze, "frozen");
    return GUA(_guaContract)._guas(_i);
  }

  function getGif() public view returns(bytes memory gif) {

    //bytes memory temp = hex"47494638396103000300a20000ffffff35a98e5f5fbcf2af4af53077e55c7f5cc0e5e5ca5c21f90401000000002c0000000003000300000304080a119b003b";
    //return BytesLib.slice(temp, 55,8);

    bytes[] memory gifs = new bytes[](IERC721Enumerable(_guaContract).totalSupply()-1);
    uint8[] memory colorIndices = new uint8[](IERC721Enumerable(_guaContract).totalSupply()-1);
    bytes2[] memory bitstreams = new bytes2[](IERC721Enumerable(_guaContract).totalSupply()-1);

    for(uint256 i = 1; i < IERC721Enumerable(_guaContract).totalSupply(); i++){
      (,,,,gifs[i-1],,,,colorIndices[i-1],bitstreams[i-1]) = _parseGuas(i);
    }

    //bytes[] memory gifs = iGUA(_guaContract).getGifs();

    bytes memory header = hex"4749463839611B000E01a20000ffffff35a98e5f5fbcf2af4af53077e55c7f5cc0e5e5ca5c21FF0B4E45545343415045322E300301010000";
    bytes memory trailer = hex"3b";

    bytes memory gce = hex"21f904050f000000";

    Point[] memory points;// = _gradient(bitstreams);

    for(uint256 i = 0; i < gifs.length; i++){
      //compute top and left for this GUA
      bytes1 top = bytes1(points[i].top);//bytes1(uint8(((20 * i) + block.timestamp) % 254));
      bytes1 left = bytes1(points[i].left);//bytes1(uint8(((i * i) + block.timestamp) % 254));


      bytes memory imgData = BytesLib.slice(gifs[i], 55, 7);
      bytes memory imgDesc = new bytes(10);
      imgDesc[0] = hex"2c";
      //top
      imgDesc[1] = top;//each data pack is 3x3, so don't have it run off the screen, hence 254 not 256
      //left
      imgDesc[3] = left;//each data pack is 3x3, so don't have it run off the screen, hence 254 not 256
      imgDesc[5] = hex"03";
      imgDesc[7] = hex"03";

      bytes memory payload = BytesLib.concat(gce, imgDesc);
      payload = BytesLib.concat(payload, imgData);
      header = BytesLib.concat(header, payload);
    }

    gif = BytesLib.concat(header, trailer);

    //bytes memory temp = hex"47494638396199009900a20000ffffff35a98e5f5fbcf2af4af53077e55c7f5cc0e5e5ca5c21FF0B4E45545343415045322E30030105000021f90405640000002c300030000300030000030408b7d09d0021f90405640000002c600060000300030000030428a0bc09003b";
    //require(false, "false");
    //return temp;
  }


  function getGifData() public view returns(string memory){
    return Base64.encode(getGif());
  }

  function getMetadata() external pure returns(string memory){
    return '"description": "TK", "name": "Fetus Movement", "createdBy": "Cai Guo-Qiang x Kanon", "yearCreated": "2022-2023"';
  }
/*
  function _gradient(uint8[] memory _densities) internal view returns (Point[] memory points) {
    points = new Point[](_densities.length);
    uint256 randSeed = uint256(uint8(block.timestamp));

    uint256 pixelDim = 3;
    uint256 hhSegment = hh/10;//27
    uint256 hhSteps = hhSegment/pixelDim;//9
    uint256 hhStep = hhSegment/hhSteps;//3

    uint256 wwSteps = ww/3;//9
    uint256 wwStep = ww/wwSteps;//3


    for(uint256 i = 0; i < _densities.length; i++){
      points[i].left = uint8(randSeed * i % wwSteps * wwStep);
      points[i].top = uint8(randSeed * i % hhSteps * hhStep + (hhSegment*uint256(_densities[i])));
    }
  }
*/
/*
  function _distributeItems(bytes[] memory _gifs, uint8[] memory _colorIndex, uint8[] memory _densities) internal view returns (Point[] memory points) {
    require(_gifs.length > 0, "not enough gifs");
    points = new Point[](_gifs.length);

    int256 radius;

    uint256 angleStep = Trig.ANGLES_IN_CYCLE / _gifs.length;
    uint256 currentAngle = 0;

    for (uint256 i = 0; i < _gifs.length; i++) {
      radius = int256((ww/2) / 10 * _densities[i]);

      radius = 1;
      currentAngle = 22; //+= 268435456;//268435456

      int256 x = Trig.cos(currentAngle);//bitwise shift by 18-8 = 10 places
      int256 y = Trig.sin(currentAngle);//bitwise shift by 18-8 = 10 places
      //y = y - 9878;

      require(false, Strings.toString(uint256(y)));

      //recenter: convert x to left; y to top
      uint256 left = uint256(x) / (10**10);//uint256(x + int256(ww)/2);
      uint256 top = uint256(y) / (10**10);//uint256(y + int256(hh)/2);


      points[i] = Point(uint8(left), uint8(top));
      currentAngle += angleStep;
    }


    return points;
  }
  */
/*
  function _radians(uint256 degrees) internal pure returns (uint16) {
    return uint16(degrees * (uint256(2**64) / 360));
  }

  function _cos(uint256 angle) internal pure returns (int256) {
    uint256 precision = 10**10;
    int256 fixedAngle = int256(angle * precision / uint256(2**64));
    return Trig.cos(fixedAngle);
  }

  function _sin(uint256 angle) internal pure returns (int256) {
    uint256 precision = 10**10;
    int256 fixedAngle = int256(angle * precision / uint256(2**64));
    return Trig.sin(fixedAngle);
  }
  */
}//end