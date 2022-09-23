// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

interface IFarm {
  function fundFOTA(uint _amount) external;
  function farmers(address _farmer) external view returns (uint, uint, uint, uint, uint, uint);
}