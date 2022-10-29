// SPDX-License-Identifier: MIT

pragma solidity =0.8.16;

contract CartoonRhinoTokenStorage {

    uint256 internal subscribeAmount;

    uint256 public constant MAX_SUPPLY = 60000;

    mapping(address => uint256[]) internal lotteryList;

    address public merge;

    address public payee;

    uint256 internal MIN_PRICE_PER;

    mapping(uint256 => bool) internal tokenIdRecord;

}