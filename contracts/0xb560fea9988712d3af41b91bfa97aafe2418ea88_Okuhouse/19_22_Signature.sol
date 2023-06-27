//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library Signature {
    function verify(uint amount, address target, bytes memory signature) internal pure returns (address) {
        bytes32 payloadHash = keccak256(abi.encode(target, amount));

        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash));
        
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v,r,s) = splitSignature(signature);

        return ecrecover(messageHash, v, r, s);
    }
    
    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
}