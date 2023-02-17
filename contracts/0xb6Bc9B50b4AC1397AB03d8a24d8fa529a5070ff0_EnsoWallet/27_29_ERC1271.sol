// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IERC1271.sol";

abstract contract ERC1271 is IERC1271 {
    using ECDSA for bytes32;

    bytes4 internal constant MAGICVALUE_BYTES = 0x20c13b0b;
    bytes4 internal constant MAGICVALUE_BYTES32 = 0x1626ba7e;
    bytes4 internal constant INVALID_SIGNATURE = 0xffffffff;

    // @notice Checks for a valid signature
    // @param hash A bytes32 hash of a message
    // @param signature The signed hash of the message
    function isValidSignature(bytes32 hash, bytes memory signature) public view override returns (bytes4 magicValue) {
        address signer = hash.recover(signature);
        magicValue = _checkSigner(signer) ? MAGICVALUE_BYTES32 : INVALID_SIGNATURE;
    }

    // @notice Checks for a valid signature
    // @param message The message that has been signed
    // @param signature The signed hash of the message
    function isValidSignature(
        bytes memory message,
        bytes memory signature
    ) public view override returns (bytes4 magicValue) {
        address signer = ECDSA.toEthSignedMessageHash(message).recover(signature);
        magicValue = _checkSigner(signer) ? MAGICVALUE_BYTES : INVALID_SIGNATURE;
    }

    // @notice Confirm signer is permitted to sign on behalf of contract
    // @dev Abstract function to implemented by importing contract
    // @param signer The address of the message signer
    // @return Bool confirming whether signer is permitted
    function _checkSigner(address signer) internal view virtual returns (bool);
}