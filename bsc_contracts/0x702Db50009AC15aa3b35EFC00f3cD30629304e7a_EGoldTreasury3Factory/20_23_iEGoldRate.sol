//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;


interface IEGoldRate {

    function fetchRate( uint256 _amt ) external view returns ( uint256 );

}