// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ILiquidatorController {

  function governance() external view returns (address);

  function isOperator(address _adr) external view returns (bool);


}