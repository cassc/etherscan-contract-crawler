// ERC-20 clock where the name dynamically syncs to the current time in UTC
//
// Symbol: UTC
// Name: 2023-06-25T00:00:00Z
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './libraries/TimeLib.sol';

contract UTC is ERC20 {
  constructor() ERC20('_', 'UTC') {
    _mint(_msgSender(), 31_536_000 * 10 ** 18);
  }

  function name() public view override returns (string memory) {
    return
      string.concat(
        Strings.toString(TimeLib.getYear(block.timestamp)),
        '-',
        _month(block.timestamp),
        '-',
        _day(block.timestamp),
        'T',
        _hour(block.timestamp),
        ':',
        _minute(block.timestamp),
        ':',
        _second(block.timestamp),
        'Z'
      );
  }

  function _month(uint256 _ts) internal pure returns (string memory) {
    return
      string.concat(
        TimeLib.getMonth(_ts) <= 9 ? '0' : '',
        Strings.toString(TimeLib.getMonth(_ts))
      );
  }

  function _day(uint256 _ts) internal pure returns (string memory) {
    return
      string.concat(
        TimeLib.getDay(_ts) <= 9 ? '0' : '',
        Strings.toString(TimeLib.getDay(_ts))
      );
  }

  function _hour(uint256 _ts) internal pure returns (string memory) {
    return
      string.concat(
        TimeLib.getHour(_ts) <= 9 ? '0' : '',
        Strings.toString(TimeLib.getHour(_ts))
      );
  }

  function _minute(uint256 _ts) internal pure returns (string memory) {
    return
      string.concat(
        TimeLib.getMinute(_ts) <= 9 ? '0' : '',
        Strings.toString(TimeLib.getMinute(_ts))
      );
  }

  function _second(uint256 _ts) internal pure returns (string memory) {
    return
      string.concat(
        TimeLib.getSecond(_ts) <= 9 ? '0' : '',
        Strings.toString(TimeLib.getSecond(_ts))
      );
  }
}