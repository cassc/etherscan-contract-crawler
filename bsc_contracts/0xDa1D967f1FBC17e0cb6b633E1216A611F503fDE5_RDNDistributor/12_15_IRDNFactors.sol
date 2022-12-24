// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;


interface IRDNFactors {

    function getFactor(uint _level, uint _tariff, uint _userId) external view returns(uint);

    function calc(uint _level, uint _tariff, uint _userId) external pure returns(uint);

    function getDecimals() external view returns(uint);
}