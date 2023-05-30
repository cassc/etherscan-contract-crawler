// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


interface iDictionary {
  function totalFortunes() external pure returns (uint256);
  function metadataHeader(uint256 _index) external pure returns (string memory);
  function getName(uint256 _index) external view returns (string memory);
}

/** @title FortuneRouter Contract
  * @author @0xAnimist
  * @notice First Onchain GIF, collaboration between Cai Guo-Qiang and Kanon
  */
contract FortuneRouter is Ownable {

  address[] public _dictionaries;
  mapping(uint256 => uint256) public _routes;
  bool public _freeze;

  uint256[] public _binaryIndexToFortuneNumber = [1, 22, 7, 19, 15, 34, 44, 11, 14, 51, 38, 52, 61, 55, 30, 32, 6, 3, 28, 58, 39, 63, 46, 5, 45, 17, 47, 56, 31, 49, 27, 43, 23, 26, 2, 41, 50, 20, 16, 24, 35, 21, 62, 36, 54, 29, 48, 12, 18, 40, 59, 60, 53, 37, 57, 9, 10, 25, 4, 8, 33, 13, 42, 0];

  uint256[] public _fortuneNumberToBinaryIndex = [63, 0, 34, 17, 58, 23, 16, 2, 59, 55, 56, 7, 47, 61, 8, 4, 38, 25, 48, 3, 37, 41, 1, 32, 39, 57, 33, 30, 18, 45, 14, 28, 15, 60, 5, 40, 43, 53, 10, 20, 49, 35, 62, 31, 6, 24, 22, 26, 46, 29, 36, 9, 11, 52, 44, 13, 27, 54, 19, 50, 51, 12, 42, 21];

  constructor() Ownable() { }

  function setDictionaries(address[] memory dictionaries_, bool freeze_) external onlyOwner {
    require(!_freeze, "frozen");
    _dictionaries = dictionaries_;

    uint256 tally = 0;

    for(uint256 i = 0; i < _dictionaries.length; i++){
      _routes[i] = iDictionary(_dictionaries[i]).totalFortunes() + tally;
      tally = _routes[i];
    }

    _freeze = freeze_;
  }

  function getDictionaries() external view returns (address[] memory) {
    return _dictionaries;
  }


  function route(uint256 _index) public view returns (address dictionary, uint256 localIndex) {
    uint256 offset;
    for(uint256 i = 0; i < _dictionaries.length; i++){
      if(_index < _routes[i]){
        localIndex = _index - offset;
        return (_dictionaries[i], localIndex);
      }else{
        offset = _routes[i];
      }
    }
  }


  function getMetadataHeader(uint256 _index) external view returns (string memory) {
    (address dictionary, uint256 localIndex) = route(_binaryIndexToFortuneNumber[_index]);
    return iDictionary(dictionary).metadataHeader(localIndex);
  }


  function getName(uint256 _index) external view returns (string memory) {
    (address dictionary, uint256 localIndex) = route(_binaryIndexToFortuneNumber[_index]);
    return iDictionary(dictionary).getName(localIndex);
  }

}//end