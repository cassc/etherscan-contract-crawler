// SPDX-License-Identifier: MIT

/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity ^0.8.0;

interface ICurvePool {
    function get_virtual_price() external view returns (uint256);

    function admin_fee() external view returns (uint256);

    function balances(uint256 index) external view returns (uint256);

    function balances(int128 index) external view returns (uint256);

    function coins(uint256 index) external view returns (address);

    // ren and sbtc pool
    function coins(int128 index) external view returns (address);
}