// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

library Sig {
    /// @dev ECDSA V,R and S components encapsulated here as we may not always be able to accept a bytes signature
    struct Components {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    error S();
    error V();
    error Length();
    error ZeroAddress();

    /// @param h Hashed data which was originally signed
    /// @param c signature struct containing V,R and S
    /// @return The recovered address
    function recover(bytes32 h, Components calldata c)
        internal
        pure
        returns (address)
    {
        // EIP-2 and malleable signatures...
        // see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol
        if (
            uint256(c.s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert S();
        }

        if (c.v != 27 && c.v != 28) {
            revert V();
        }

        address recovered = ecrecover(h, c.v, c.r, c.s);

        if (recovered == address(0)) {
            revert ZeroAddress();
        }

        return recovered;
    }

    /// @param sig Valid ECDSA signature
    /// @return v The verification bit
    /// @return r First 32 bytes
    /// @return s Next 32 bytes
    function split(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        if (sig.length != 65) {
            revert Length();
        }

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