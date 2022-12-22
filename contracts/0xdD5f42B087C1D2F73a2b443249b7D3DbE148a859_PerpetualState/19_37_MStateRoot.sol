/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

abstract contract MStateRoot {
    function getValidiumVaultRoot() public view virtual returns (uint256);

    function getValidiumTreeHeight() public view virtual returns (uint256);

    function getRollupVaultRoot() public view virtual returns (uint256);

    function getRollupTreeHeight() public view virtual returns (uint256);

    /*
      Returns true iff vaultId is in the valid vault ids range,
      i.e. could appear in either the validium or rollup vaults trees.
    */
    function isVaultInRange(uint256 vaultId) internal view virtual returns (bool);

    /*
      Returns true if vaultId is a valid validium vault id.

      Note: when this function returns false it might mean that vaultId is invalid and does not
      guarantee that vaultId is a valid rollup vault id.
    */
    function isValidiumVault(uint256 vaultId) internal view virtual returns (bool);

    /*
      Returns true if vaultId is a valid rollup vault id.

      Note: when this function returns false it might mean that vaultId is invalid and does not
      guarantee that vaultId is a valid validium vault id.
    */
    function isRollupVault(uint256 vaultId) internal view virtual returns (bool);

    /*
      Given a valid vaultId, returns its leaf index in the validium/rollup tree.

      Note: this function does not assert the validity of vaultId, make sure to explicitly assert it
      when required.
    */
    function getVaultLeafIndex(uint256 vaultId) internal pure virtual returns (uint256);
}