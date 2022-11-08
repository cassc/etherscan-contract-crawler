// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title: Planetary Scores™ Token Verifier
/// @author: @madebymozart | madebymozart.eth

/// Npm Imports
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract PlanetaryTokenVerifier {
    using ECDSA for bytes32;

    address private _signer;

    event SignerUpdated(address _newSigner);

    constructor(address _initialSigner) {
        _signer = _initialSigner;
    }

    function _setSigner(address _newSigner) internal {
        _signer = _newSigner;
        emit SignerUpdated(_signer);
    }

    function _verifyTokenForAddress(
        string calldata _salt,
        bytes calldata _token,
        address _address
    ) internal view returns (bool) {
        return
            keccak256(abi.encode(_salt, address(this), _address))
                .toEthSignedMessageHash()
                .recover(_token) == _signer;
    }
}