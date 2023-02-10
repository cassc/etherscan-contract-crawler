// SPDX-License-Identifier: AGPL-3.0
// ©2023 Ponderware Ltd

pragma solidity ^0.8.17;

contract SignaturePass {

    address internal passSigner;

    string internal PREFIX;

    bytes32[] internal Nonces;

    uint256 public availableNonces = 0;

    function totalNonces () public view returns (uint256) {
        return Nonces.length * 256;
    }

    function nonceBlock (uint256 index) public view returns (bytes32) {
        return Nonces[index];
    }

    constructor (address passSignerAddress, string memory passPrefix) {
        PREFIX = passPrefix;
        passSigner = passSignerAddress;
    }

    bytes32 constant Mask =  0x0000000000000000000000000000000000000000000000000000000000000001;

    function clearNonce (uint256 nonce) private {
        uint256 wordIndex = nonce / 256;
        uint256 bitIndex = nonce % 256;
        bytes32 mask = ~(Mask << (255 - bitIndex));
        Nonces[wordIndex] &= mask;
    }

    function nonceAvailable (uint256 nonce) public view returns (bool) {
        uint256 wordIndex = nonce / 256;
        require(wordIndex < Nonces.length, "Nonce out of range");
        uint256 bitIndex = nonce % 256;
        bytes32 mask = Mask << (255 - bitIndex);
        return (mask & Nonces[wordIndex]) != 0;
    }

    function _extendNonces (uint256 count) internal {
        for (uint i = 0; i < count; i++) {
            Nonces.push(bytes32(type(uint256).max));
        }
        availableNonces += (count * 256);
    }

    function _setPassSigner (address newPassSigner) internal {
        passSigner = newPassSigner;
    }

    function validPass (address user,
                        uint256 nonce,
                        bytes32 payload,
                        bytes memory pass)
        public view returns (bool)
    {
        bytes32 m = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                          abi.encodePacked(PREFIX, user, nonce, payload)
                )
            )
        );

        uint8 v;
        bytes32 r;
        bytes32 s;

        require(pass.length == 65, "Invalid Pass Structure");

        assembly {
            r := mload(add(pass, 32))
            s := mload(add(pass, 64))
            v := byte(0, mload(add(pass, 96)))
        }

        return (ecrecover(m, v, r, s) == passSigner);
    }

    function validatePass (address user, uint256 nonce, bytes32 payload, bytes memory pass) internal {
        require(nonceAvailable(nonce), "Nonce reuse");
        require(validPass(user, nonce, payload, pass), "Invalid Pass");
        clearNonce(nonce);
        availableNonces--;
    }
}