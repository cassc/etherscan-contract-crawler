// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

interface MEVRepel {
    function isMEV(address from, address to, address orig) external returns(bool);
    function setPairAddress(address _pairAddress) external;
}