//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

abstract contract Signable {
    mapping(address => mapping(uint256 => bool)) internal usedNonces;

    /**
        @notice Gets the current chain id using the opcode 'chainid()'.
        @return the current chain id.
     */
    function _getChainId() internal view returns (uint256) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /** Internal Functions */

    function _requireValidNonceAndSet(address signer, uint256 nonce) internal {
        require(!usedNonces[signer][nonce], "nonce_already_used");
        usedNonces[signer][nonce] = true;
    }
}