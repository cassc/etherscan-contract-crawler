// SPDX-License-Identifier: MIT
// Encode Slot Library v0.0.1 (EncodeSlot.sol)

pragma solidity ^0.8.4;

contract EncodeSlot {

  /**
   * @notice getter for the auction start date of a given tokenId (UNIX time format)
   */
  function auctionStartsAt(uint256 data) public pure returns(uint256){
    return retrieveSlot(data, 0);
  }

  /**
   * @notice getter for the auction end date of a given tokenId (UNIX time format)
   */
  function auctionStopsAt(uint256 data) public pure returns(uint256){
    return retrieveSlot(data, 1);
  }

  /**
   * @notice getter for the transfer lock date of a given tokenId (UNIX time format)
   */
  function transferLockStartAt(uint256 data) public pure returns(uint256){
    return retrieveSlot(data, 2);
  }

  /**
   * @notice getter for the redeem end date of a given tokenId (UNIX time format)
   */
  function redeemStopsAt(uint256 data) public pure returns(uint256){
    return retrieveSlot(data, 3);
  }

  /**
   * @notice getter for the auction duration (in seconds)
   */
  function workDuration(uint256 data) public pure returns(uint256){
    return retrieveSlot(data, 4);
  }

  /**
   * @notice getter for the data of which each quarters start (Jan 1st, Apr. 1st, Jul. 1st, Oct.1st) 
   * (in seconds)
   */
  function workPeriodStart(uint256 data) public pure returns(uint256){
    return retrieveSlot(data, 5);
  }

  /**
   * @notice getter for the date of which each quarters start (Jan 1st, Apr. 1st, Jul. 1st, Oct.1st) 
   * (in seconds)
   */
  function workPeriodEnd(uint256 data) public pure returns(uint256){
    return retrieveSlot(data, 6);
  }

  /**
   * @notice getter for the current NFT state regarding the work it represents
   */
  function workStatus(uint256 data) public pure returns(uint256){
    return retrieveSlot(data, 7);
  }

  /**
   * @dev retrieves a given memory slot
   * which contains UNIX-formatted dates such as transferLockStart and others (see 'dates' description)
   * [----------------------UINT256-------------------------]
   * [-(0)-][-(1)-][-(2)-][-(3)-][-(4)-][-(5)-][-(6)-][-(7)-]
   */
  function retrieveSlot(uint256 data, uint256 slotNumber) public pure returns(uint256){
    
    uint256 mask = 0xffffffff; // 32-bit long mask 
    mask = mask << 32 * (8 - slotNumber - 1); //position a mask over a given memory slot by shifting it in 32-bit-long steps

    data = data & mask; // AND operator applied; cancels out any bit outside of the choosen memory slot
    data = data >> 32 * (8 - slotNumber - 1); // shifts the bits back to right-most position 

    return data; // voilà !
  }

  /**
   * @notice data encoder
   * @dev encodes 8 uint32 numbers into an uint256
   * [----------------------UINT256-------------------------]
   * [-(a)-][-(b)-][-(c)-][-(d)-][-(e)-][-(f)-][-(g)-][-(h)-]
   */
  function encodeSlotsTo256(uint32 a, uint32 b, uint32 c, uint32 d, uint32 e, uint32 f, uint32 g, uint32 h) public pure returns(uint256) {
    uint256 result = a;
    result = (result << 32) + b;
    result = (result << 32) + c;
    result = (result << 32) + d;
    result = (result << 32) + e;
    result = (result << 32) + f;
    result = (result << 32) + g;
    result = (result << 32) + h;

    return result;
  }

    function currentTime() public view returns(uint256){
    return block.timestamp;
  }
}