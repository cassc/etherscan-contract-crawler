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

import "TokenRegister.sol";
import "PerpetualStorage.sol";

/**
  Extension of the TokenRegister contract for StarkPerpetual.

  The change is that asset registration defines the system asset,
  and permitted only once.
*/
abstract contract PerpetualTokenRegister is PerpetualStorage, TokenRegister {
    event LogSystemAssetType(uint256 assetType);

    function registerToken(
        uint256, /* assetType */
        bytes calldata /* assetInfo */
    ) external override {
        revert("UNSUPPORTED_FUNCTION");
    }

    function registerToken(
        uint256, /* assetType */
        bytes memory, /* assetInfo */
        uint256 /* quantum */
    ) public override {
        revert("UNSUPPORTED_FUNCTION");
    }

    // NOLINTNEXTLINE external-function.
    function getSystemAssetType() public view returns (uint256) {
        return systemAssetType;
    }

    function registerSystemAssetType(uint256 assetType, bytes calldata assetInfo)
        external
        onlyTokensAdmin
    {
        require(systemAssetType == uint256(0), "SYSTEM_ASSET_TYPE_ALREADY_SET");
        systemAssetType = assetType;
        super.registerToken(assetType, assetInfo, 1);
        emit LogSystemAssetType(assetType);
    }
}