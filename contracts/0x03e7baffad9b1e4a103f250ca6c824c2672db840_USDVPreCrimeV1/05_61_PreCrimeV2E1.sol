// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@layerzerolabs/lz-evm-v1-0.7/contracts/interfaces/ILayerZeroEndpoint.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../PreCrimeV2.sol";

abstract contract PreCrimeV2E1 is PreCrimeV2 {
    using SafeCast for uint32;

    uint32 internal immutable localEid;

    constructor(uint32 _localEid, address _endpoint, address _simulator) PreCrimeV2(_endpoint, _simulator) {
        localEid = _localEid;
    }

    function _getLocalEid() internal view override returns (uint32) {
        return localEid;
    }

    function _getInboundNonce(uint32 _srcEid, bytes32 _sender) internal view override returns (uint64) {
        bytes memory path = _getPath(_srcEid, _sender);
        return ILayerZeroEndpoint(lzEndpoint).getInboundNonce(_srcEid.toUint16(), path);
    }

    function _getPath(uint32 _srcEid, bytes32 _sender) internal view virtual returns (bytes memory);
}