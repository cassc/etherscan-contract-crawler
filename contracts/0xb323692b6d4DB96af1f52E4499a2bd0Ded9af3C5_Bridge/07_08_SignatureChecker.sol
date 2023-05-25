// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./TonUtils.sol";

contract SignatureChecker is TonUtils {
    function checkSignature(bytes32 digest, Signature memory sig) public pure {
        require(sig.signer != address(0), "ECDSA: zero signer"); // The `ecrecover` function returns zero on failure, so if sig.signer == 0 then any signature will be accepted regardless of whether it is cryptographically valid.
        require(sig.signature.length == 65, "ECDSA: invalid signature length");
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        bytes memory signature = sig.signature;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );

        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, digest));
        require(
            ecrecover(prefixedHash, v, r, s) == sig.signer,
            "Wrong signature"
        );
    }

    function getSwapDataId(SwapData memory data)
        public
        view
        returns (bytes32 result)
    {
        result = keccak256(
            abi.encode(
                0xDA7A,
                address(this),
                block.chainid,
                data.receiver,
                data.token,
                data.amount,
                data.tx.address_hash,
                data.tx.tx_hash,
                data.tx.lt
            )
        );
    }

    function getNewSetId(uint256 oracleSetHash, address[] memory set)
        public
        view
        returns (bytes32 result)
    {
        result = keccak256(
            abi.encode(0x5e7, address(this), block.chainid, oracleSetHash, set)
        );
    }

    function getNewLockStatusId(bool newLockStatus, uint256 nonce)
        public
        view
        returns (bytes32 result)
    {
        result = keccak256(
            abi.encode(0xB012, address(this), block.chainid, newLockStatus, nonce)
        );
    }

    function getNewDisableToken(bool isDisable, address tokenAddress,  uint256 nonce)
        public
        view
        returns (bytes32 result)
    {
        result = keccak256(
            abi.encode(0xD15A, address(this), block.chainid, isDisable, tokenAddress, nonce)
        );
    }
}