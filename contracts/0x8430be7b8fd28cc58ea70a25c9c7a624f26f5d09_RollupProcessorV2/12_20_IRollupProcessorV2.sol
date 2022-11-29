// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {IRollupProcessor} from "./IRollupProcessor.sol";

// @dev For documentation of the functions within this interface see RollupProcessorV2 contract
interface IRollupProcessorV2 is IRollupProcessor {
    function getCapped() external view returns (bool);

    function defiInteractionHashes(uint256) external view returns (bytes32);
}