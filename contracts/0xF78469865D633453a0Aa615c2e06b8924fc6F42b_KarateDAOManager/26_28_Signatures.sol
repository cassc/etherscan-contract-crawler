pragma solidity ^0.8.0;

library Signatures {

    struct SigData {
    	uint8 v;
    	bytes32 r;
    	bytes32 s;
    }

    function verifyMessage(SigData calldata sigData, bytes32 _hashedMessage) public pure returns (address) {
      bytes memory prefix = "\x19Ethereum Signed Message:\n32";
      bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
      address signer = ecrecover(prefixedHashMessage, sigData.v, sigData.r, sigData.s);
      return signer;
    }
}