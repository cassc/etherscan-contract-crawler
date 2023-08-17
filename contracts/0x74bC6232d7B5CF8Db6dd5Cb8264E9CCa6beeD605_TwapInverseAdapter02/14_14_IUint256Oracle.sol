// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

interface IUint256Oracle {
  function getUint256(bytes memory params) external view returns (uint256);
}