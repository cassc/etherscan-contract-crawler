// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

/*
    A less bulky version of OpenZeppelin's anti-malleability stuff
*/
library CheapSafeEC
{
    error MalleableSignature();

    /** Recovers the signer address (or address(0)), while disallowing malleable high-S signatures */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (address signer)
    {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) { revert MalleableSignature(); }
        return ecrecover(hash, v, r, s);
    }
}