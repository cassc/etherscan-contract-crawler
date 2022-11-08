// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Interface HistoricalData

pragma solidity >=0.8.0;

interface IHistoricalData {
    struct BlockData {
        address producer;
        uint32 mainchainBlockNumber;
        bytes32 dataHash;
    }

    /// @notice Validate a V2 sidechain block
    /// @param _sidechainBlockNumber the sidechain block number to validate
    /// @param _depthDiff the minimal depth diff to validate sidechain block
    /// @return bool is the sidechain block valid
    /// @return address the producer of the sidechain block
    function isValidBlock(
        uint32 _sidechainBlockNumber,
        uint32 _depthDiff
    ) external view returns (bool, address);

    /// @notice Get mainchain block number of last sidechain block
    function getEthBlockStamp() external view returns (uint256);

    /// @notice Get the producer of last sidechain block
    function getLastProducer() external view returns (address);

    /// @notice Get sidechain block count
    function getSidechainBlockCount() external view returns (uint256);

    /// @notice Get a V2 sidechain block
    function getSidechainBlock(
        uint256
    ) external view returns (BlockData memory);
}