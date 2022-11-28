// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.13;
import "./Interfaces.sol";

interface IOptionsHealthCheck {
  function IsSafeToCreateOption ( IStructs.Fees memory premium_,IStructs.InputParams memory inParams_ ) external returns ( bool );
}