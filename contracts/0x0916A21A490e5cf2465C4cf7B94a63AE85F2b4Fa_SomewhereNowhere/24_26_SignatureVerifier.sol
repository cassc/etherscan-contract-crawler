// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import './interfaces/ISignatureVerifier.sol';
import './Roles.sol';

abstract contract SignatureVerifier is ISignatureVerifier, Roles {
    using ECDSA for bytes32;

    bytes32 private immutable _domainSeparator;
    address private _signingAddress;

    constructor(bytes32 domainSeparator) {
        _domainSeparator = domainSeparator;
    }

    modifier signatureIsValid(bytes calldata signature, bytes32 message)
        virtual {
        if (!_verify(signature, message)) revert SignatureIsNotValid();
        _;
    }

    function setSigningAddress(address signingAddress)
        public
        virtual
        override
        onlyController
    {
        _signingAddress = signingAddress;

        emit SigningAddressUpdated(signingAddress);
    }

    function getSigningAddress()
        public
        view
        virtual
        override
        returns (address)
    {
        return _signingAddress;
    }

    function _verify(bytes calldata signature, bytes32 message)
        internal
        view
        virtual
        returns (bool)
    {
        if (_signingAddress == address(0)) revert SigningAddressIsZeroAddress();

        return
            keccak256(abi.encodePacked('\x19\x01', _domainSeparator, message))
                .recover(signature) == _signingAddress;
    }
}