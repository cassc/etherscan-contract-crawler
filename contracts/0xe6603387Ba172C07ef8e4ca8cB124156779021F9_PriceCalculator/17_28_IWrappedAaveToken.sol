//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.4;

interface IWrappedAaveToken {

  function ATOKEN() external view returns (address);

  function staticToDynamicAmount(uint value) external view returns (uint);

}