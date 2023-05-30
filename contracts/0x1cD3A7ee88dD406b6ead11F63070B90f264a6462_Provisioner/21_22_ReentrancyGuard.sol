// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;


abstract contract ReentrancyGuard
{
  uint256 private _status = 1;


  modifier nonReentrant ()
  {
    require(_status == 1, "reentrance");


    _status = 2;

    _;

    _status = 1;
  }
}