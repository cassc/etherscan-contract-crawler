// SPDX-License-Identifier: MIT

/**
 *
 * @title IArrngController.sol. Interface for the arrngController.
 *
 * @author arrng https://arrng.xyz/
 *
 */

pragma solidity 0.8.19;

interface IArrngController {
  /**
   *
   * @dev requestRandomWords: request 1 to n uint256 integers
   * requestRandomWords is overloaded. In this instance you can
   * call it without explicitly declaring a refund address, with the
   * refund being paid to the tx.origin for this call.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestRandomWords(
    uint256 numberOfNumbers_
  ) external payable returns (uint256 uniqueID_);

  /**
   *
   * @dev requestRandomWords: request 1 to n uint256 integers
   * requestRandomWords is overloaded. In this instance you must
   * specify the refund address for unused native token.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param refundAddress_: the address for refund of native token
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestRandomWords(
    uint256 numberOfNumbers_,
    address refundAddress_
  ) external payable returns (uint256 uniqueID_);

  /**
   *
   * @dev requestRandomNumbersInRange: request 1 to n integers within
   * a given range (e.g. 1 to 10,000)
   * requestRandomNumbersInRange is overloaded. In this instance you can
   * call it without explicitly declaring a refund address, with the
   * refund being paid to the tx.origin for this call.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param minValue_: the min of the range
   * @param maxValue_: the max of the range
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestRandomNumbersInRange(
    uint256 numberOfNumbers_,
    uint256 minValue_,
    uint256 maxValue_
  ) external payable returns (uint256 uniqueID_);

  /**
   *
   * @dev requestRandomNumbersInRange: request 1 to n integers within
   * a given range (e.g. 1 to 10,000)
   * requestRandomNumbersInRange is overloaded. In this instance you must
   * specify the refund address for unused native token.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param minValue_: the min of the range
   * @param maxValue_: the max of the range
   * @param refundAddress_: the address for refund of native token
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestRandomNumbersInRange(
    uint256 numberOfNumbers_,
    uint256 minValue_,
    uint256 maxValue_,
    address refundAddress_
  ) external payable returns (uint256 uniqueID_);

  /**
   *
   * @dev requestWithMethod: public method to allow calls specifying the
   * arrng method, allowing functionality to be extensible without
   * requiring a new controller contract
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param minValue_: the min of the range
   * @param maxValue_: the max of the range
   * @param refundAddress_: the address for refund of native token
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestWithMethod(
    uint256 numberOfNumbers_,
    uint256 minValue_,
    uint256 maxValue_,
    address refundAddress_,
    uint32 method_
  ) external payable returns (uint256 uniqueID_);
}