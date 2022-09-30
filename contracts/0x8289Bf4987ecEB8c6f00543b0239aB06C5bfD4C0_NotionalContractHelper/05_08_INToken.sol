// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface INToken {
  function allowance ( address account, address spender ) external view returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address account ) external view returns ( uint256 );
  function currencyId () external view returns ( uint16 );
  function decimals () external view returns ( uint8 );
  function getPresentValueAssetDenominated () external view returns ( int256 );
  function getPresentValueUnderlyingDenominated () external view returns ( int256 );
  function name () external view returns ( string memory );
  function proxy () external view returns ( address );
  function symbol () external view returns ( string memory );
  function totalSupply () external view returns ( uint256 );
  function transfer ( address to, uint256 amount ) external returns ( bool );
  function transferFrom ( address from, address to, uint256 amount ) external returns ( bool );
}