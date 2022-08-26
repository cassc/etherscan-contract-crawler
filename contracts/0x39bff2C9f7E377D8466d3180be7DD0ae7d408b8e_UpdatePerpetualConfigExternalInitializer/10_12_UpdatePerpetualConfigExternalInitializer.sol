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

import "ExternalInitializer.sol";
import "PerpetualConstants.sol";
import "PerpetualStorage.sol";

/*
  This contract is simple impelementation of an external initializing contract
  that configures/reconfigures main contract configuration.
*/
contract UpdatePerpetualConfigExternalInitializer is
    ExternalInitializer,
    PerpetualStorage,
    PerpetualConstants
{
    event LogGlobalConfigurationApplied(bytes32 configHash);
    event LogAssetConfigurationApplied(uint256 assetId, bytes32 configHash);

    function initialize(bytes calldata data) external override {
        require(data.length % 64 == 0, "NOT_WORDS_PAIRS_DATA_LENGTH_ERROR");
        uint256 GLOBAL_CONFIG_KEY = uint256(~0);
        uint256 nConfigPairs = data.length / 64;
        uint256 offset = 32;
        bytes memory _data = data;
        for (uint256 pair = 0; pair < nConfigPairs; pair++) {
            uint256 configKey;
            bytes32 configHash;
            assembly {
                configKey := mload(add(_data, offset))
                configHash := mload(add(_data, add(32, offset)))
            }
            require(uint256(configHash) < K_MODULUS, "INVALID_CONFIG_HASH");

            if (configKey == GLOBAL_CONFIG_KEY) {
                globalConfigurationHash = configHash; // NOLINT costly-loop.
                emit LogGlobalConfigurationApplied(configHash);
            } else {
                require(configKey < PERPETUAL_ASSET_ID_UPPER_BOUND, "INVALID_ASSET_ID");
                configurationHash[configKey] = configHash; // NOLINT costly-loop.
                emit LogAssetConfigurationApplied(configKey, configHash);
            }

            offset += 64;
        }
        emit LogExternalInitialize(data);
    }
}