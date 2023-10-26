// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/*
  _______ .______     .___________.____    __    ____  __  .__   __.  _______     _______.
 /  _____||   _  \    |           |\   \  /  \  /   / |  | |  \ |  | |   ____|   /       |
|  |  __  |  |_)  |   `---|  |----` \   \/    \/   /  |  | |   \|  | |  |__     |   (----`
|  | |_ | |      /        |  |       \            /   |  | |  . `  | |   __|     \   \    
|  |__| | |  |\  \----.   |  |        \    /\    /    |  | |  |\   | |  |____.----)   |   
 \______| | _| `._____|   |__|         \__/  \__/     |__| |__| \__| |_______|_______/    
                                                                                     
*/

/// @title Extended Bitmaps
/// @author Developed by Labrys on behalf of GRT Wines
/// @custom:contributor Sean L (slongdotexe)
/// @dev    Extended Bitmaps library is utilised to provide a gas efficent mechanism for rapidly manipulating large
//          quantities of boolean statuses. It is assumed that the structure of the Bitmap will be reliably calculated off-chain
library ExtendedBitmap {
  struct BitMap {
    mapping(uint256 => uint256) _data;
  }

  function getBucket(BitMap storage bitmap, uint256 bucketIndex)
    internal
    view
    returns (uint256 _bucket)
  {
    _bucket = bitmap._data[bucketIndex];
  }

  function setBucket(
    BitMap storage bitmap,
    uint256 bucketIndex,
    uint256 bucketContents
  ) internal {
    bitmap._data[bucketIndex] = bucketContents;
  }

  function getMaskedBucket(
    BitMap storage bitmap,
    uint256 startIndex,
    uint256 endIndex,
    uint256 index
  ) internal view returns (uint256) {
    uint256 startBucket = startIndex >> 8;
    uint256 endBucket = endIndex >> 8;
    uint256 currentBucket = index >> 8;
    uint256 result = getBucket(bitmap, currentBucket);
    //If the currentBucket we're accessing is the first bucket for this range of bits, mask the first N bits
    if (currentBucket == startBucket) {
      //The number of bits we want to mask off the start of the word
      uint256 maskNStarting = startIndex - 256 * startBucket;
      result &= type(uint256).max << maskNStarting;
    }
    //If the currentBucket we're accessing is the last bucket for this range of bits, mask the last N bits
    if (currentBucket == endBucket) {
      //The number of bits we want to mask off the end of the word
      uint256 maskNEnding = 255 - (endIndex - 256 * endBucket);
      result &= type(uint256).max >> maskNEnding;
    }
    return result;
  }

  // ################################################################
  // ## ALL BELOW FUNCTIONS ARE DIRECTLY COPIED FROM OPEN-ZEPPELIN ##
  // ################################################################

  /**
   * @dev Returns whether the bit at `index` is set.
   */
  function get(BitMap storage bitmap, uint256 index)
    internal
    view
    returns (bool)
  {
    uint256 bucket = index >> 8;
    uint256 mask = 1 << (index & 0xff);
    return bitmap._data[bucket] & mask != 0;
  }

  /**
   * @dev Sets the bit at `index` to the boolean `value`.
   */
  function setTo(
    BitMap storage bitmap,
    uint256 index,
    bool value
  ) internal {
    if (value) {
      set(bitmap, index);
    } else {
      unset(bitmap, index);
    }
  }

  /**
   * @dev Sets the bit at `index`.
   */
  function set(BitMap storage bitmap, uint256 index) internal {
    uint256 bucket = index >> 8;
    uint256 mask = 1 << (index & 0xff);
    bitmap._data[bucket] |= mask;
  }

  /**
   * @dev Unsets the bit at `index`.
   */
  function unset(BitMap storage bitmap, uint256 index) internal {
    uint256 bucket = index >> 8;
    uint256 mask = 1 << (index & 0xff);
    bitmap._data[bucket] &= ~mask;
  }
}