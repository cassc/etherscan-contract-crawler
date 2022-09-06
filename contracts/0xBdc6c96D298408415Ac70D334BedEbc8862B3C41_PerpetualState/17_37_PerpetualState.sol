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

import "PerpetualEscapes.sol";
import "UpdatePerpetualState.sol";
import "Configuration.sol";
import "ForcedTradeActionState.sol";
import "ForcedWithdrawalActionState.sol";
import "Freezable.sol";
import "MainGovernance.sol";
import "StarkExOperator.sol";
import "AcceptModifications.sol";
import "StateRoot.sol";
import "TokenQuantization.sol";
import "SubContractor.sol";

contract PerpetualState is
    MainGovernance,
    SubContractor,
    Configuration,
    StarkExOperator,
    Freezable,
    AcceptModifications,
    TokenQuantization,
    ForcedTradeActionState,
    ForcedWithdrawalActionState,
    StateRoot,
    PerpetualEscapes,
    UpdatePerpetualState
{
    // Empty state is 8 words (256 bytes) To pass as uint[] we need also head & len fields (64).
    uint256 constant INITIALIZER_SIZE = 384; // Padded address(32), uint(32), Empty state(256+64).

    /*
      Initialization flow:
      1. Extract initialization parameters from data.
      2. Call internalInitializer with those parameters.
    */
    function initialize(bytes calldata data) external override {
        // This initializer sets roots etc. It must not be applied twice.
        // I.e. it can run only when the state is still empty.
        require(sharedStateHash == bytes32(0x0), "STATE_ALREADY_INITIALIZED");
        require(configurationHash[GLOBAL_CONFIG_KEY] == bytes32(0x0), "STATE_ALREADY_INITIALIZED");

        require(data.length == INITIALIZER_SIZE, "INCORRECT_INIT_DATA_SIZE_384");

        (
            address escapeVerifierAddress_,
            uint256 initialSequenceNumber,
            uint256[] memory initialState
        ) = abi.decode(data, (address, uint256, uint256[]));

        initGovernance();
        Configuration.initialize(PERPETUAL_CONFIGURATION_DELAY);
        StarkExOperator.initialize();
        //  Validium tree is not utilized in Perpetual. Initializing its root and height to -1.
        StateRoot.initialize(
            initialSequenceNumber,
            uint256(-1), // validiumVaultRoot.
            initialState[0], // rollupVaultRoot.
            initialState[2], // orderRoot.
            uint256(-1), // validiumTreeHeight.
            initialState[1], // rollupTreeHeight.
            initialState[3] // orderTreeHeight.
        );
        sharedStateHash = keccak256(abi.encodePacked(initialState));
        PerpetualEscapes.initialize(escapeVerifierAddress_);
    }

    /*
      The call to initializerSize is done from MainDispatcherBase using delegatecall,
      thus the existing state is already accessible.
    */
    function initializerSize() external view override returns (uint256) {
        return INITIALIZER_SIZE;
    }

    function validatedSelectors() external pure override returns (bytes4[] memory selectors) {
        uint256 len_ = 1;
        uint256 index_ = 0;

        selectors = new bytes4[](len_);
        selectors[index_++] = PerpetualEscapes.escape.selector;
        require(index_ == len_, "INCORRECT_SELECTORS_ARRAY_LENGTH");
    }

    function identify() external pure override returns (string memory) {
        return "StarkWare_PerpetualState_2022_2";
    }
}