// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Abstract HistoricalData

pragma solidity ^0.8.0;

import "../IHistoricalData.sol";

abstract contract AHistoricalData is IHistoricalData {
    event VertexInserted(uint256 _parent);

    /// @notice Record block data produced from PoS contract
    /// @param _parent the parent block that current block appends to
    /// @param _producer the producer of the sidechain block
    /// @param _dataHash hash of the data held by the block
    function recordBlock(
        uint256 _parent,
        address _producer,
        bytes32 _dataHash
    ) internal virtual returns (uint256);

    /// @notice Record information about the latest sidechain block
    /// @param _producer the producer of the sidechain block
    /// @param _sidechainBlockCount count of total sidechain blocks
    function updateLatest(
        address _producer,
        uint256 _sidechainBlockCount
    ) internal virtual;
}