// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SponsoredCall} from "../types/CallTypes.sol";

interface IGelatoRelay {
    event LogCallWithSyncFee(
        address indexed target,
        address feeToken,
        uint256 fee,
        bytes32 taskId
    );

    event LogCallWithSyncFeeV2(
        address indexed target,
        bytes32 indexed correlationId
    );

    function gelato() external view returns (address);

    function callWithSyncFee(
        address _target,
        bytes calldata _data,
        address _feeToken,
        uint256 _fee,
        bytes32 _taskId
    ) external;

    function callWithSyncFeeV2(
        address _target,
        bytes calldata _data,
        bool _isRelayContext,
        bytes32 _correlationId
    ) external;

    function sponsoredCall(
        SponsoredCall calldata _call,
        address _sponsor,
        address _feeToken,
        uint256 _oneBalanceChainId,
        uint256 _nativeToFeeTokenXRateNumerator,
        uint256 _nativeToFeeTokenXRateDenominator,
        bytes32 _correlationId
    ) external;
}