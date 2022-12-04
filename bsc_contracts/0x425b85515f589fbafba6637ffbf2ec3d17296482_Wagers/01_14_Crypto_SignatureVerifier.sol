// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @custom:security-contact [email protected]
contract SignatureVerifier {
    address public signer;

    constructor(address _signer) {
        require(_signer != address(0), "zero address can not be signer");
        signer = _signer;
    }

    function setSigner(address _signer) internal {
        require(_signer != address(0), "zero address can not be signer");
        signer = _signer;
        emit SetSigner(_signer);
    }

    // verify returns true if signature by signer matches the hash
    function verify(bytes32 messageHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        require(signer != address(0), "zero address can not be signer");
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return recoverSigner(ethSignedMessageHash, r, s, v) == signer;
    }

    // verifyRSV returns true if signature by signer matches the hash
    function verifyRSV(
        bytes32 messageHash,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) internal view returns (bool) {
        require(signer != address(0), "zero address can not be signer");
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, r, s, v) == signer;
    }

    function getEthSignedMessageHash(bytes32 messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) internal pure returns (address) {
        require(v == 27 || v == 28, "invalid v value");
        require(
            uint256(s) <
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A1,
            "invalid s value"
        );
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory signature)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(signature.length == 65, "invalid signature length");
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    }

    event SetSigner(address _signer);
}