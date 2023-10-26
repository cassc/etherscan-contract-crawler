// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity ^0.8.0;

interface IVaultRateLimiter {
    function tryMint(address _caller, address _asset, uint64 _amount) external returns (uint64);

    function tryBurn(address _caller, address _asset, uint64 _amount) external;

    error ConsumingMoreThanAvailable(uint64 requested, uint64 available);
    error Unauthorized();
}