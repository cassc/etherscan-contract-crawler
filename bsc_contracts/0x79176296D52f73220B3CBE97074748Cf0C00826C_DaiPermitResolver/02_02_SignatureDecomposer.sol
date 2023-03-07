// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

abstract contract SignatureDecomposer {
    function r(bytes calldata sig_) internal pure returns (bytes32) { return bytes32(sig_[0:32]); }
    function s(bytes calldata sig_) internal pure returns (bytes32) { return bytes32(sig_[32:64]); }
    function v(bytes calldata sig_) internal pure returns (uint8) { return uint8(bytes1(sig_[64:65])); }
}