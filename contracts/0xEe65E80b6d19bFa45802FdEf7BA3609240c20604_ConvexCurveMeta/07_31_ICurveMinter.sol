// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

// so
interface ICurveMinter {
  function mint(address gauge_addr) external;

  function minted(address arg0, address arg1) external view returns (uint256);
}