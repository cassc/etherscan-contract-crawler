// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@layerzerolabs/lz-evm-v1-0.7/contracts/interfaces/ILayerZeroEndpoint.sol";
import "@layerzerolabs/lz-evm-oapp-v2/contracts/standards/precrime/extensions/PreCrimeV2E1.sol";
import "@layerzerolabs/lz-evm-oapp-v1/contracts/lzApp/LzApp.sol";
import "./USDVPreCrimeV2.sol";

contract USDVPreCrimeV1 is USDVPreCrimeV2 {
    using SafeCast for uint32;

    uint32 internal immutable localEid;

    constructor(
        uint32 _localEid,
        address _endpoint,
        address _usdvSimulator,
        bool _isMain
    ) USDVPreCrimeV2(_endpoint, _usdvSimulator, _isMain) {
        localEid = _localEid;
    }

    function _getLocalEid() internal view override returns (uint32) {
        return localEid;
    }

    function _getInboundNonce(uint32 _srcEid, bytes32 _sender) internal view override returns (uint64) {
        bytes memory path = _getPath(_srcEid, _sender);
        return ILayerZeroEndpoint(lzEndpoint).getInboundNonce(_srcEid.toUint16(), path);
    }

    function _getPath(uint32 _srcEid, bytes32 /*_sender*/) internal view virtual returns (bytes memory) {
        return LzApp(oapp).trustedRemoteLookup(_srcEid.toUint16());
    }
}