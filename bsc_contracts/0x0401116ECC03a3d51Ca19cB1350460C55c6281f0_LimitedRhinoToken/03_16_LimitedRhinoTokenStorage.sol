// SPDX-License-Identifier: MIT

pragma solidity =0.8.16;

import {List} from  "../struct/RhinoTokenStructs.sol";

contract LimitedRhinoTokenStorage {

    uint256 internal subscribeAmount100;
    uint256 internal subscribeAmount200;
    uint256 internal subscribeAmount300;

    uint256 public constant MAX_SUPPLY_100 = 3960;
    uint256 public constant MAX_SUPPLY_200 = 2310;
    uint256 public constant MAX_SUPPLY_300 = 330;

    mapping(uint256 => uint256) public idByLimitedTime;

    mapping(address => mapping(uint256 => List)) public lotteryList;

    address public merge;

    address public payee;

    uint256 internal MIN_PRICE_PER;

    mapping(uint256 => address) public firstHolder;

}