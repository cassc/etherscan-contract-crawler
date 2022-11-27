// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './GnosisSafe/handler/DefaultCallbackHandler.sol';


contract SummonUtils is DefaultCallbackHandler {

    function splitSignature(bytes memory sig)
       public
       pure
       returns (
           bytes32 r,
           bytes32 s,
           uint8 v
       )
   {
       require(sig.length == 65, "invalid signature length");

       assembly {
           r := mload(add(sig, 32))
           s := mload(add(sig, 64))
           v := byte(0, mload(add(sig, 96)))
       }
   }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
       public
       pure
       returns (address)
   {
       (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

       return ecrecover(_ethSignedMessageHash, v, r, s);
   }

}