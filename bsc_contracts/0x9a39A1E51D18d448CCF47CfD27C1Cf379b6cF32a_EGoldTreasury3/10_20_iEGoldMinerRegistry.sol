//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "../core/Treasury3/library/EGoldUtils.sol";

interface IEGoldMinerRegistry {

    function setMiner( uint256 _type , EGoldUtils.minerStruct memory _miner) external;

    function fetchMinerInfo( uint256 _type ) external view returns ( EGoldUtils.minerStruct memory );

    function fetchMinerRate( uint256 _type ) external view returns ( uint256 );

}