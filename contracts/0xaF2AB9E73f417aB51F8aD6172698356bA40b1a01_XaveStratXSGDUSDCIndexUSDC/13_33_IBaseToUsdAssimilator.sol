// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IBaseToUsdAssimilator {
  function baseDecimals (  ) external view returns ( uint256 );
  function baseToken (  ) external view returns ( address );
  function getRate (  ) external view returns ( uint256 );
  function intakeNumeraire ( int128 _amount ) external returns ( uint256 amount_ );
  function intakeNumeraireLPRatio ( uint256 _baseWeight, uint256 _quoteWeight, address _addr, int128 _amount ) external returns ( uint256 amount_ );
  function intakeRaw ( uint256 _amount ) external returns ( int128 amount_ );
  function intakeRawAndGetBalance ( uint256 _amount ) external returns ( int128 amount_, int128 balance_ );
  function oracle (  ) external view returns ( address );
  function outputNumeraire ( address _dst, int128 _amount ) external returns ( uint256 amount_ );
  function outputRaw ( address _dst, uint256 _amount ) external returns ( int128 amount_ );
  function outputRawAndGetBalance ( address _dst, uint256 _amount ) external returns ( int128 amount_, int128 balance_ );
  function usdc (  ) external view returns ( address );
  function viewNumeraireAmount ( uint256 _amount ) external view returns ( int128 amount_ );
  function viewNumeraireAmountAndBalance ( address _addr, uint256 _amount ) external view returns ( int128 amount_, int128 balance_ );
  function viewNumeraireBalance ( address _addr ) external view returns ( int128 balance_ );
  function viewNumeraireBalanceLPRatio ( uint256 _baseWeight, uint256 _quoteWeight, address _addr ) external view returns ( int128 balance_ );
  function viewRawAmount ( uint256 _amount ) external view returns ( uint256 amount_ );
  function viewRawAmountLPRatio ( uint256 _baseWeight, uint256 _quoteWeight, address _addr, int128 _amount ) external view returns ( uint256 amount_ );
}