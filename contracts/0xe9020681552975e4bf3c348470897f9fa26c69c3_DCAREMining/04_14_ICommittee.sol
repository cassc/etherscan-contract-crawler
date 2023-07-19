// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

interface ICommittee {

  function committee(uint256 _idx) external view returns (address);

}