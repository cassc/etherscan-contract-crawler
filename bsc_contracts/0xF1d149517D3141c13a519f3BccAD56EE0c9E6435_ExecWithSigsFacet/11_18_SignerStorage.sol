// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

using EnumerableSet for EnumerableSet.AddressSet;

struct SignerStorage {
    EnumerableSet.AddressSet executorSigners;
    EnumerableSet.AddressSet checkerSigners;
}

bytes32 constant _SIGNER_STORAGE_POSITION = keccak256(
    "gelato.diamond.signer.storage"
);

function _addExecutorSigner(address _executor) returns (bool) {
    return _signerStorage().executorSigners.add(_executor);
}

function _removeExecutorSigner(address _executor) returns (bool) {
    return _signerStorage().executorSigners.remove(_executor);
}

function _isExecutorSigner(address _executorSigner) view returns (bool) {
    return _signerStorage().executorSigners.contains(_executorSigner);
}

function _executorSignerAt(uint256 _index) view returns (address) {
    return _signerStorage().executorSigners.at(_index);
}

function _executorSigners() view returns (address[] memory) {
    return _signerStorage().executorSigners.values();
}

function _numberOfExecutorSigners() view returns (uint256) {
    return _signerStorage().executorSigners.length();
}

function _addCheckerSigner(address _checker) returns (bool) {
    return _signerStorage().checkerSigners.add(_checker);
}

function _removeCheckerSigner(address _checker) returns (bool) {
    return _signerStorage().checkerSigners.remove(_checker);
}

function _isCheckerSigner(address _checker) view returns (bool) {
    return _signerStorage().checkerSigners.contains(_checker);
}

function _checkerSignerAt(uint256 _index) view returns (address) {
    return _signerStorage().checkerSigners.at(_index);
}

function _checkerSigners() view returns (address[] memory checkers) {
    return _signerStorage().checkerSigners.values();
}

function _numberOfCheckerSigners() view returns (uint256) {
    return _signerStorage().checkerSigners.length();
}

function _signerStorage() pure returns (SignerStorage storage ess) {
    bytes32 position = _SIGNER_STORAGE_POSITION;
    assembly {
        ess.slot := position
    }
}