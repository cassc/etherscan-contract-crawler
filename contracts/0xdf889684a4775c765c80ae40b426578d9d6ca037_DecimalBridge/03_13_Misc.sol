// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

library Misc {
    function recover(
        bytes32 hashedMsg,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");
        address signer = ecrecover(hashedMsg, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");
        return signer;
    }
}