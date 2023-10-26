// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity ^0.8.0;

import {Delta} from "./IUSDV.sol";

interface IOperator {
    function tryConsume(address _caller, uint64 _amount) external returns (uint64);

    function refill(address _caller, uint64 _extraTokens) external;

    function getSyncFees(
        address _caller,
        Delta[] calldata _deltas,
        uint64 _usdvAmount
    ) external returns (uint64 syncFee);

    function getRemintFees(
        address _caller,
        uint32 _toColor,
        Delta[] calldata _deltas,
        uint64 _usdvAmount
    ) external returns (uint64 minterRemintFee, uint64 operatorRemintFee);
}