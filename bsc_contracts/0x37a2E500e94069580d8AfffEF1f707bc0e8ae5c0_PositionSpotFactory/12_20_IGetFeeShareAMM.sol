// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface IGetFeeShareAMM {
    /// @notice fee share for liquidity provider
    /// @return the rate share
    function feeShareAmm() external view returns (uint32);
}