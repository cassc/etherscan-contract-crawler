pragma solidity ^0.5.0;


contract SignatureVerifier {
    function validateNodeSignature(
        string memory nodeHardwareLicenseId,
        uint256 sigNonce,
        bytes memory signature
    ) internal view returns (address signer) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        (v, r, s) = splitSignature(signature);
        bytes32 hash = keccak256(abi.encodePacked(nodeHardwareLicenseId, sigNonce, this));
        bytes32 hashWithHeader = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        return ecrecover(hashWithHeader, v, r, s);
    }

    function splitSignature(bytes memory signature)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(signature, 32))
            // second 32 bytes
            s := mload(add(signature, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(signature, 96)))
        }

        return (v, r, s);
    }
}
