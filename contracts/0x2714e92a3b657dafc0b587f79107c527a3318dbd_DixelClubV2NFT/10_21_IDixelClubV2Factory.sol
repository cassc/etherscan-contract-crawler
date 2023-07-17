// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.13;

import "./Shared.sol";

interface IDixelClubV2Factory {
  function beneficiary() external view returns (address);
  function mintingFee() external view returns (uint256);
}