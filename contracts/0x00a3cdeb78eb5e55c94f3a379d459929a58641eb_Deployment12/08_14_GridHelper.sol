// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "@openzeppelin/contracts/utils/Strings.sol";

library GridHelper {
  uint256 public constant MAX_GRID_INDEX = 8;

  /**
    * @dev slice array of bytes
    * @param data The array of bytes to slice
    * @param start The start index
    * @param len The length of the slice
    * @return The sliced array of bytes
   */

  function slice(bytes memory data, uint256 start, uint256 len) internal pure returns (bytes memory) {
      bytes memory b = new bytes(len);
      for (uint256 i = 0; i < len; i++) {
        b[i] = data[i + start];
      }
      return b;
  }

  /**
    * @dev combine two arrays of strings
    * @param a The first array
    * @param b The second array
    * @return The combined array
   */

  function combineStringArrays(string[] memory a, string[] memory b) public pure returns (string[] memory) {
    string[] memory c = new string[](a.length + b.length);
    for (uint256 i = 0; i < a.length; i++) {
        c[i] = a[i];
    }
    for (uint256 i = 0; i < b.length; i++) {
        c[i + a.length] = b[i];
    }
    return c;
  }

  /**
    * @dev combine two arrays of uints
    * @param a The first array
    * @param b The second array
    * @return The combined array
   */

  function combineUintArrays(uint256[] memory a, uint256[] memory b) public pure returns (uint256[] memory) {
      uint256[] memory c = new uint256[](a.length + b.length);
      for (uint256 i = 0; i < a.length; i++) {
          c[i] = a[i];
      }
      for (uint256 i = 0; i < b.length; i++) {
          c[i + a.length] = b[i];
      }
      return c;
  }

  /**
    * @dev wrap a string in a transform group
    * @param x The x position
    * @param y The y position
    * @param data The data to wrap
    * @return The wrapped string
   */

  function groupTransform(string memory x, string memory y, string memory data) internal pure returns (string memory) {
    return string.concat("<g transform='translate(", x, ",", y, ")'>", data, "</g>");
  }

  /**
    * @dev convert a uint to bytes
    * @param x The uint to convert
    * @return b The bytes
   */

  function uintToBytes(uint256 x) internal pure returns (bytes memory b) {
      b = new bytes(32);
      assembly {
          mstore(add(b, 32), x)
      } //  first 32 bytes = length of the bytes value
  }

  /**
    * @dev convert bytes with length equal to bytes32 to uint
    * @param value The bytes to convert
    * @return The uint
   */

  function bytesToUint(bytes memory value) internal pure returns(uint) {
    uint256 num = uint256(bytes32(value));
    return num;
  }

  /**
    * @dev convert bytes with length less than bytes32 to uint
    * @param a The bytes to convert
    * @return The uint
   */

  function byteSliceToUint (bytes memory a) internal pure returns(uint) {
    bytes32 padding = bytes32(0);
    bytes memory formattedSlice = slice(bytes.concat(padding, a), 1, 32);

    return bytesToUint(formattedSlice);
  }

  /**
    * @dev get a byte from a random number at a given position
    * @param rand The random number
    * @param slicePosition The position of the byte to slice
    * @return The random byte
   */

  function getRandByte(uint rand, uint slicePosition) internal pure returns(uint) {
    bytes memory bytesRand = uintToBytes(rand);
    bytes memory part = slice(bytesRand, slicePosition, 1);
    return byteSliceToUint(part);
  }

  /**
    * @dev convert a string to a uint
    * @param s The string to convert
    * @return The uint
   */

  function stringToUint(string memory s) internal pure returns (uint) {
      bytes memory b = bytes(s);
      uint result = 0;
      for (uint256 i = 0; i < b.length; i++) {
          uint256 c = uint256(uint8(b[i]));
          if (c >= 48 && c <= 57) {
              result = result * 10 + (c - 48);
          }
      }
      return result;
  }

  /**
    * @dev repeat an object a given number of times with given offsets
    * @param object The object to repeat
    * @param times The number of times to repeat
    * @param offsetBytes The offsets to use
    * @return The repeated object
   */

  function repeatGivenObject(string memory object, uint times, bytes memory offsetBytes) internal pure returns (string memory) {
    // uint sliceSize = offsetBytes.length / (times * 2); // /2 for x and y
    require(offsetBytes.length % (times * 2) == 0, "offsetBytes length must be divisible by times * 2");
    string memory output = "";
    for (uint256 i = 0; i < times; i++) {
      string memory xOffset = string(slice(offsetBytes, 2*i * offsetBytes.length / (times * 2), offsetBytes.length / (times * 2)));
      string memory yOffset = string(slice(offsetBytes, (2*i + 1) * offsetBytes.length / (times * 2), offsetBytes.length / (times * 2)));
      output = string.concat(
        output,
        groupTransform(xOffset, yOffset, object)
      );
    }
    return output;
  }

  /**
    * @dev convert a single string to an array of uints
    * @param values The string to convert
    * @param numOfValues The number of values in the string
    * @param lengthOfValue The length of each value in the string
    * @return The array of uints
   */

  function setUintArrayFromString(string memory values, uint numOfValues, uint lengthOfValue) internal pure returns (uint[] memory) {
    uint[] memory output = new uint[](numOfValues);
    for (uint256 i = 0; i < numOfValues; i++) {
      output[i] = stringToUint(string(slice(bytes(values), i*lengthOfValue, lengthOfValue)));
    }
    return output;
  }

  /**
    * @dev get the sum of an array of uints
    * @param arr The array to sum
    * @return The sum
   */

  function getSumOfUintArray(uint[] memory arr) internal pure returns (uint) {
    uint sum = 0;
    for (uint i = 0; i < arr.length; i++) {
      sum += arr[i];
    }
    return sum;
  }

  /**
    * @dev constrain a value to the range 0-255, must be between -255 and 510
    * @param value The value to constrain
    * @return The constrained value
   */

  function constrainToHex(int value) internal pure returns (uint) {
    require(value >= -255 && value <= 510, "Value out of bounds.");
    if (value < 0) { // if negative, make positive
      return uint(0 - value);
    }
    else if (value > 255) { // if greater than 255, count back from 255
      return uint(255 - (value - 255));
    } else {
      return uint(value);
    }
  }

  /**
    * @dev create an array of equal probabilities for a given number of values
    * @param numOfValues The number of values
    * @return The array of probabilities
   */

  function createEqualProbabilityArray(uint numOfValues) internal pure returns (uint[] memory) {
    uint oneLess = numOfValues - 1;
    uint[] memory probabilities = new uint[](oneLess);
    for (uint256 i = 0; i < oneLess; ++i) {
      probabilities[i] = 256 * (i + 1) / numOfValues;
    }
    return probabilities;
  }

  /**
    * @dev get a single object from a string of object numbers
    * @param objectNumbers The string of objects
    * @param channelValue The hex value of the channel
    * @param numOfValues The number of values in the string
    * @param valueLength The length of each value in the string
    * @return The object
   */

  function getSingleObject(string memory objectNumbers, uint channelValue, uint numOfValues, uint valueLength) internal pure returns (uint) {
    
    // create probability array assuming all objects have equal probability
    uint[] memory probabilities = createEqualProbabilityArray(numOfValues);

    uint[] memory objectNumbersArray = setUintArrayFromString(objectNumbers, numOfValues, valueLength);

    uint oneLess = numOfValues - 1;

    for (uint256 i = 0; i < oneLess; ++i) {
      if (channelValue < probabilities[i]) {
        return objectNumbersArray[i];
      }
    }
    return objectNumbersArray[oneLess];
  }
}