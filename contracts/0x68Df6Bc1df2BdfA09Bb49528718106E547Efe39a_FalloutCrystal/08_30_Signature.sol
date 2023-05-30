// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error HashUsed();
error SignatureFailed(address signatureAddress, address signer);

abstract contract Signature {
    using ECDSA for bytes32;

    address private _signer;
    mapping(bytes32 => bool) private _isHashUsed;

    constructor(address signerAddress_){
        _signer = signerAddress_;
    }

    function _setSignerAddress(address signerAddress_) internal {
        _signer = signerAddress_;
    }

    function signerAddress() public view returns(address)  {
        return _signer;
    }

    // Signature verfification
    modifier onlySignedTx(
        bytes32 hash_,
        bytes calldata signature_
    ) {
        if (_isHashUsed[hash_]) revert HashUsed();
        
        address signatureAddress = hash_
                .toEthSignedMessageHash()
                .recover(signature_);
        if (signatureAddress != _signer) revert SignatureFailed(signatureAddress, _signer);

        _isHashUsed[hash_] = true;
        _;
    }
}