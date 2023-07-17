// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @author: @props

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


/**
 * @title Library of utility functions.
 */
library Utils {

  /**
  * @notice isUnique iterates over all elements in an array to determine whether or 
  * not it contains repeated values. Returns false if a repeated value is found.
  * @param items the array of items to evaluate
  * @return true if the array does not contain repeated items, false if not
  * @dev We use for loops instead of storage based constructs because doing so
  * allows comparison to be run entirely in memory and therefore saves gas.
  */
  function isUnique(uint256[] memory items) internal pure returns (bool) {
      for (uint i = 0; i < items.length; i++) {
          for (uint k = i + 1; k < items.length; k++) {
              if (items[i] == items[k]) {
                  return false;
              }
          }
      }
      return true;
  }


    function compareStrings(string memory a, string memory b) internal view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

  function makeLeaf(address _addr, uint amount) internal pure returns (string memory) {
      return string(abi.encodePacked(toAsciiString(_addr), "_", Strings.toString(amount)));
  }

  function toAsciiString(address x) internal pure returns (string memory) {
      bytes memory s = new bytes(40);
      for (uint i = 0; i < 20; i++) {
          bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
          bytes1 hi = bytes1(uint8(b) / 16);
          bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
          s[2*i] = toChar(hi);
          s[2*i+1] = toChar(lo);            
      }
      return string(s);
  }

  function shuffle(uint256[] memory numberArr, bool returnRandomIndex, uint seed) internal view returns(uint256[] memory){
        if(!returnRandomIndex){
             for (uint256 i = 0; i < numberArr.length; i++) {
                uint256 n = i + uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed))) % (numberArr.length - i);
                uint256 temp = numberArr[n];
                numberArr[n] = numberArr[i];
                numberArr[i] = temp;
            }
        }
        else{
            uint randomHash = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed))) % numberArr.length;
            uint256[] memory retNumberArr = new uint256[](1);
            retNumberArr[0] = numberArr[randomHash];
            numberArr = retNumberArr;
        }
       
        return numberArr;
    }

  /**
  * @notice toChar converts a byte array to characters.
  * @param b bytes to convert characters
  * @return bytes character
  * @dev We use for loops instead of storage based constructs because doing so
  * allows comparison to be run entirely in memory and therefore saves gas.
  */
  function toChar(bytes1 b) internal pure returns (bytes1) {
      if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
      else return bytes1(uint8(b) + 0x57);
  }


}