// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IGameEngine{
    function stake ( uint tokenId ) external;
    function alertStake (uint tokenId) external;
}