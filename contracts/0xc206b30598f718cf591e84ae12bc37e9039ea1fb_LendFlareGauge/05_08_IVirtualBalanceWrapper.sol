// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

interface IVirtualBalanceWrapperFactory {
    function createWrapper(address _op) external returns (address);
}

interface IVirtualBalanceWrapper {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function stakeFor(address _for, uint256 _amount) external returns (bool);
    function withdrawFor(address _for, uint256 amount) external returns (bool);
}