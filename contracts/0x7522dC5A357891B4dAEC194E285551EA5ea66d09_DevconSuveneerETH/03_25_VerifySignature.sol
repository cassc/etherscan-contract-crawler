// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

contract VerifySignature {
    using Strings for uint256;
    
    // use this function to get the hash of any string
    function getHash(string memory str) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(str));
    }
    
    // take the keccak256 hashed message from the getHash function above and input into this function
    // this function prefixes the hash above with \x19Ethereum signed message:\n32 + hash
    // and produces a new hash signature
    function getEthSignedHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function getEthMsgdHash(string memory message) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", bytes(message).length ,message));
    }

    function getEthBytesHash(bytes memory data) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", data.length ,data));
    }
    
    // input the getEthSignedHash results and the signature hash results
    // the output of this function will be the account number that signed the original message
    function verify(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function verifyStringSign(string memory _msg, bytes memory _signature) public pure returns (address) {
        bytes32 msgHash = keccak256(abi.encodePacked(_msg));
        
        return verify(msgHash, _signature);
    }

    function splitSignature(bytes memory sig) public pure
        returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
    
    // verify messages, signed by ethereum wallet
    function verifyEthString(string memory _msg, bytes memory _signature) public pure returns (address) {
        return verify(getEthMsgdHash(_msg), _signature);
    }

    function verifyEthHash(bytes32 _hash, bytes memory _signature) public pure returns (address) {
        return verify(getEthSignedHash(_hash), _signature);
    }

    function verifyEthBytes(bytes memory _data, bytes memory _signature) public pure returns (address) {
        return verify(getEthBytesHash(_data), _signature);
    }
}