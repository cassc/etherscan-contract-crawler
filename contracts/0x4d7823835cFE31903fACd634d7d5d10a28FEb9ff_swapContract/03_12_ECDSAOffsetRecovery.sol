// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract ECDSAOffsetRecovery 
{
    function getHashPacked(address user, uint256 amountWithFee, bytes32 originalTxHash) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(user, amountWithFee, originalTxHash));
    }

    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function ecOffsetRecover(bytes32 hash, bytes memory signature, uint256 offset)
        public
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Divide the signature in r, s and v variables with inline assembly.
        assembly {
            r := mload(add(signature, add(offset, 0x20)))
            s := mload(add(signature, add(offset, 0x40)))
            v := byte(0, mload(add(signature, add(offset, 0x60))))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        }

        // bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        // hash = keccak256(abi.encodePacked(prefix, hash));
        // solium-disable-next-line arg-overflow
        return ecrecover(toEthSignedMessageHash(hash), v, r, s);
    }
}