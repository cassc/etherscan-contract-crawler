// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct ExecWithSigsStorage {
    mapping(bytes32 => bool) wasSignatureUsedAlready;
}

bytes32 constant _EXEC_WITH_SIGS_STORAGE = keccak256(
    "gelato.diamond.execWithSigs.storage"
);

function _wasSignatureUsedAlready(bytes calldata _signature)
    view
    returns (bool)
{
    return
        _execWithSigsStorage().wasSignatureUsedAlready[keccak256(_signature)];
}

function _setWasSignatureUsedAlready(bytes calldata _signature) {
    _execWithSigsStorage().wasSignatureUsedAlready[
        keccak256(_signature)
    ] = true;
}

//solhint-disable-next-line private-vars-leading-underscore
function _execWithSigsStorage()
    pure
    returns (ExecWithSigsStorage storage ewss)
{
    bytes32 position = _EXEC_WITH_SIGS_STORAGE;
    assembly {
        ewss.slot := position
    }
}