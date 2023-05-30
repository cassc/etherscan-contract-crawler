// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8;

interface IBondingCalculator {
    function valuation( address pair_, uint amount_ ) external view returns ( uint _value );

    function getBondTokenValue( address _pair, uint amount_ ) external view returns ( uint _value );

    function getPrincipleTokenValue( address _pair, uint amount_ ) external view returns ( uint _value );

    function getPrincipleTokenValue( address _pairSwap, address _pairPrinciple, uint amount_ ) external view returns ( uint _value );

    function getBondTokenPrice( address _pair ) external view returns ( uint _value );

    function getBondTokenPrice( address _pairSwap, address _pairPrinciple ) external view returns ( uint _value );
}