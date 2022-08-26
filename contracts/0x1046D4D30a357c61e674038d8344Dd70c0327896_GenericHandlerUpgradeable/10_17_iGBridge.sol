// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface iGBridge{

    function genericDeposit( uint8 _destChainID, bytes32 _resourceID ) external returns ( uint64 );

    function fetch_chainID( ) external view returns ( uint8 );

}