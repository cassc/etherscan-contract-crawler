// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/// @author: artiffine.com & manifold.xyz
/// @title: Manifold Marketplace Contract Created for NFC

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol';

import './IIdentityVerifier.sol';

contract NFCastleIdentityVerifier is AdminControl, IIdentityVerifier {
    using ECDSA for bytes32;

    address private _signer;

    constructor(address signer) {
        _signer = signer;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(IIdentityVerifier).interfaceId || super.supportsInterface(interfaceId);
    }

    function setSigner(address signer) public adminRequired {
        _signer = signer;
    }

    function verify(
        uint40 listingId,
        address identity,
        address,
        uint256,
        uint24,
        uint256,
        address,
        bytes calldata data
    ) external view override returns (bool) {
        (bytes32 message, bytes memory signature) = abi.decode(data, (bytes32, bytes));
        bytes32 expectedMessage = keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n25', identity, listingId));
        if (message != expectedMessage) return false;
        if (message.recover(signature) != _signer) return false;
        return true;
    }
}