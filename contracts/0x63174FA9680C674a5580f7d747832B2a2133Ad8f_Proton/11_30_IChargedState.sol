// SPDX-License-Identifier: MIT

// IChargedSettings.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity >=0.6.0;

import "./IChargedSettings.sol";

/**
 * @notice Interface for Charged State
 */
interface IChargedState {

  /***********************************|
  |             Public API            |
  |__________________________________*/

  function getDischargeTimelockExpiry(address contractAddress, uint256 tokenId) external view returns (uint256 lockExpiry);
  function getReleaseTimelockExpiry(address contractAddress, uint256 tokenId) external view returns (uint256 lockExpiry);
  function getBreakBondTimelockExpiry(address contractAddress, uint256 tokenId) external view returns (uint256 lockExpiry);

  function isApprovedForDischarge(address contractAddress, uint256 tokenId, address operator) external view returns (bool);
  function isApprovedForRelease(address contractAddress, uint256 tokenId, address operator) external view returns (bool);
  function isApprovedForBreakBond(address contractAddress, uint256 tokenId, address operator) external view returns (bool);
  function isApprovedForTimelock(address contractAddress, uint256 tokenId, address operator) external view returns (bool);

  function isEnergizeRestricted(address contractAddress, uint256 tokenId) external view returns (bool);
  function isCovalentBondRestricted(address contractAddress, uint256 tokenId) external view returns (bool);

  function getDischargeState(address contractAddress, uint256 tokenId, address sender) external view
    returns (bool allowFromAll, bool isApproved, uint256 timelock, uint256 tempLockExpiry);
  function getReleaseState(address contractAddress, uint256 tokenId, address sender) external view
    returns (bool allowFromAll, bool isApproved, uint256 timelock, uint256 tempLockExpiry);
  function getBreakBondState(address contractAddress, uint256 tokenId, address sender) external view
    returns (bool allowFromAll, bool isApproved, uint256 timelock, uint256 tempLockExpiry);

  /***********************************|
  |      Only NFT Owner/Operator      |
  |__________________________________*/

  function setDischargeApproval(address contractAddress, uint256 tokenId, address operator) external;
  function setReleaseApproval(address contractAddress, uint256 tokenId, address operator) external;
  function setBreakBondApproval(address contractAddress, uint256 tokenId, address operator) external;
  function setTimelockApproval(address contractAddress, uint256 tokenId, address operator) external;
  function setApprovalForAll(address contractAddress, uint256 tokenId, address operator) external;

  function setPermsForRestrictCharge(address contractAddress, uint256 tokenId, bool state) external;
  function setPermsForAllowDischarge(address contractAddress, uint256 tokenId, bool state) external;
  function setPermsForAllowRelease(address contractAddress, uint256 tokenId, bool state) external;
  function setPermsForRestrictBond(address contractAddress, uint256 tokenId, bool state) external;
  function setPermsForAllowBreakBond(address contractAddress, uint256 tokenId, bool state) external;

  function setDischargeTimelock(
    address contractAddress,
    uint256 tokenId,
    uint256 unlockBlock
  ) external;

  function setReleaseTimelock(
    address contractAddress,
    uint256 tokenId,
    uint256 unlockBlock
  ) external;

  function setBreakBondTimelock(
    address contractAddress,
    uint256 tokenId,
    uint256 unlockBlock
  ) external;

  /***********************************|
  |         Only NFT Contract         |
  |__________________________________*/

  function setTemporaryLock(
    address contractAddress,
    uint256 tokenId,
    bool isLocked
  ) external;

  /***********************************|
  |          Particle Events          |
  |__________________________________*/

  event ChargedSettingsSet(address indexed settingsController);

  event DischargeApproval(address indexed contractAddress, uint256 indexed tokenId, address indexed owner, address operator);
  event ReleaseApproval(address indexed contractAddress, uint256 indexed tokenId, address indexed owner, address operator);
  event BreakBondApproval(address indexed contractAddress, uint256 indexed tokenId, address indexed owner, address operator);
  event TimelockApproval(address indexed contractAddress, uint256 indexed tokenId, address indexed owner, address operator);

  event TokenDischargeTimelock(address indexed contractAddress, uint256 indexed tokenId, address indexed operator, uint256 unlockBlock);
  event TokenReleaseTimelock(address indexed contractAddress, uint256 indexed tokenId, address indexed operator, uint256 unlockBlock);
  event TokenBreakBondTimelock(address indexed contractAddress, uint256 indexed tokenId, address indexed operator, uint256 unlockBlock);
  event TokenTempLock(address indexed contractAddress, uint256 indexed tokenId, uint256 unlockBlock);

  event PermsSetForRestrictCharge(address indexed contractAddress, uint256 indexed tokenId, bool state);
  event PermsSetForAllowDischarge(address indexed contractAddress, uint256 indexed tokenId, bool state);
  event PermsSetForAllowRelease(address indexed contractAddress, uint256 indexed tokenId, bool state);
  event PermsSetForRestrictBond(address indexed contractAddress, uint256 indexed tokenId, bool state);
  event PermsSetForAllowBreakBond(address indexed contractAddress, uint256 indexed tokenId, bool state);
}