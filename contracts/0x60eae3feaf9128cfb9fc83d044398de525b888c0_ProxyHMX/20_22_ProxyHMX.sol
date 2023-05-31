// SPDX-License-Identifier: MIT
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
pragma solidity 0.8.18;

import {ProxyOFTV2} from "./ProxyOFTV2.sol";

contract ProxyHMX is ProxyOFTV2 {
  constructor(address _token, uint8 _sharedDecimals, address _lzEndpoint)
    ProxyOFTV2(_token, _sharedDecimals, _lzEndpoint)
  {}
}
