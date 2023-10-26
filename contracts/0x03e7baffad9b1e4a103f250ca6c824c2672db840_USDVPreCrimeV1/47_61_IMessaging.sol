// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity ^0.8.0;

import "@layerzerolabs/lz-evm-oapp-v2/contracts/standards/oft/interfaces/IOFT.sol";
import {MessagingFee, MessagingParams, MessagingReceipt} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {Delta} from "../../usdv/interfaces/IUSDV.sol";

interface IMessaging {
    error NotUSDV(address sender);
    error NotImplemented();
    error NotMainChain();

    event SetPerColorExtraGas(uint32 dstEid, uint8 msgType, uint extraGas);

    struct SendParam {
        uint32 dstEid;
        bytes32 to;
        uint32 color;
        uint64 amount;
        uint64 theta;
    }

    function send(
        SendParam calldata _pram,
        bytes calldata _extraOptions,
        MessagingFee calldata _msgFee,
        address payable _refundAddress,
        bytes calldata _composeMsg
    ) external payable returns (MessagingReceipt memory msgReceipt);

    function syncDelta(
        uint32 _dstEid,
        Delta[] calldata _deltas,
        bytes calldata _extraOptions,
        MessagingFee calldata _msgFee,
        address payable _refundAddress
    ) external payable returns (MessagingReceipt memory msgReceipt);

    function quoteSendFee(
        uint32 _dstEid,
        bytes calldata _extraOptions,
        bool _useLZToken,
        bytes calldata _composeMsg
    ) external view returns (uint nativeFee, uint lzTokenFee);

    function quoteSyncDeltaFee(
        uint32 _dstEid,
        Delta[] calldata _deltas,
        bytes calldata _extraOptions,
        bool _useLZToken
    ) external view returns (uint nativeFee, uint lzTokenFee);

    function remint(
        Delta[] calldata _deltas,
        uint32 _feeColor,
        uint64 _feeAmount,
        uint64 _feeTheta,
        bytes calldata _extraOptions,
        MessagingFee calldata _msgFee,
        address payable _refundAddress
    ) external payable returns (MessagingReceipt memory msgReceipt);

    function quoteRemintFee(
        Delta[] calldata _deltas,
        bytes calldata _extraOptions,
        bool _useLZToken
    ) external view returns (uint nativeFee, uint lzTokenFee);
}