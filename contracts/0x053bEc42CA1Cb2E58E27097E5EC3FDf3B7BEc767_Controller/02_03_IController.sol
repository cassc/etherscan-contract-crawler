// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IController {

  function governance() external view returns (address);

  function isOperator(address _adr) external view returns (bool);


}