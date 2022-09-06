//SPDX-License-Identifier: MIT  
pragma solidity ^0.8.4;  

/*
StarLoop SDK v0.02 (off chain ZK VRF SDK)
author @hwonder
*/

contract StarLoop {

    address notary = 0xF9C2Ba78aE44ba98888B0e9EB27EB63d576F261B;
    uint expiry = 3;

    function processVrfSigned(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint bytemap,
        uint nstamp,
        uint q
    ) internal view virtual returns (uint) {
        bytes32 msgHash = keccak256(abi.encodePacked(q, bytemap, nstamp));
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix,msgHash));
        address signer = ecrecover(prefixedHashMessage, v, r, s);
        require(notary == signer, "Invalid Notarization");
        require(block.number < ( nstamp + expiry), "Invalid");
        return q;
    }

}