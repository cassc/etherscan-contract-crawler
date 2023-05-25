// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

library MultisigUtils {
    // @notice Extracts the r, s, and v parameters to `ecrecover(...)` from the signature at position `index` in a densely packed signatures bytes array.
    // @dev Based on [OpenZeppelin's ECRecovery](https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ECRecovery.sol)
    // @param signatures   The signatures bytes array
    // @param index        The index of the signature in the bytes array (0 indexed)
    function parseSignature(bytes memory signatures, uint256 index)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        uint256 offset = index * 65;
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        assembly {
            // solium-disable-line security/no-inline-assembly
            r := mload(add(signatures, add(32, offset)))
            s := mload(add(signatures, add(64, offset)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(65, offset))), 0xff)
        }

        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "invalid v of signature(r, s, v)");
    }
}