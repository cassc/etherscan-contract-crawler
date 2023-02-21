// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { ITokenBuyer } from "../interfaces/ITokenBuyer.sol";

contract Signatures {
    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    /// @notice Accepts signatures from permit2, rejects otherwise.
    /// @param hash Hash of the data to be signed.
    /// @param signature Signature byte array associated with hash.
    /// @return magicValue The function selector if the function passes.
    function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bytes4 magicValue) {
        if (msg.sender == ITokenBuyer(address(this)).permit2()) return MAGICVALUE;

        hash;
        signature;
        return bytes4(0);
    }
}