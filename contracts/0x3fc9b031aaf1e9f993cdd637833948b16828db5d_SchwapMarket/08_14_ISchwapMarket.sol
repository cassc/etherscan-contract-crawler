// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

interface ISchwapMarket {
    function getCurrentEpoch() external view returns (uint);
    function getEmissions(uint _epoch) external view returns (uint);
    function getPairVolume(address _pair, uint _epoch) external view returns (uint);
    function getUserVolume(address _pair, address _user, uint _epoch) external view returns (uint);
}