// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CallWithERC2771} from "../types/CallTypes.sol";

interface IGelatoRelayERC2771 {
    event LogCallWithSyncFeeERC2771(
        address indexed target,
        bytes32 indexed correlationId
    );

    function callWithSyncFeeERC2771(
        CallWithERC2771 calldata _call,
        address _feeToken,
        bytes calldata _userSignature,
        bool _isRelayContext,
        bytes32 _correlationId
    ) external;

    function sponsoredCallERC2771(
        CallWithERC2771 calldata _call,
        address _sponsor,
        address _feeToken,
        uint256 _oneBalanceChainId,
        bytes calldata _userSignature,
        uint256 _nativeToFeeTokenXRateNumerator,
        uint256 _nativeToFeeTokenXRateDenominator,
        bytes32 _correlationId
    ) external;
}