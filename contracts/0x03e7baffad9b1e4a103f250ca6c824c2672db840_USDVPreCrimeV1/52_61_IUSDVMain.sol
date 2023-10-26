// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity ^0.8.0;
import "./IUSDV.sol";

interface IUSDVMain is IUSDV {
    event Reminted(Delta[] deltas, uint64 remintFee);

    function remint(uint32 _surplusColor, uint64 _surplusAmount, uint32[] calldata _deficits, uint64 _feeCap) external;

    function remintAck(Delta[] calldata _deltas, uint32 _feeColor, uint64 _feeAmount, uint64 _feeTheta) external;
}