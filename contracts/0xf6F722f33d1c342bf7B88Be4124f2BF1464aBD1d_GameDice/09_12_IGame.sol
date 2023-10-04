// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

interface IGame {
    function play(uint256 _rolls, uint256 _bet, uint256[50] memory _data, uint256 _stake, address _referral) external payable returns (uint256);
    function getMaxPayout(uint256 _bet, uint256[50] memory _data) external view returns (uint256);
}