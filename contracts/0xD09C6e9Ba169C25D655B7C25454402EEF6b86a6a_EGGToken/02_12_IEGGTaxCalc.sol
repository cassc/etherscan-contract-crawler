// SPDX-License-Identifier: GPL-3.0

/// @title Interface for EGGTaxCalc

/*
&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day
*/

pragma solidity ^0.8.17;

interface IEGGTaxCalc {
  function getTaxRate(address sender) external view returns (uint256, uint256);
}