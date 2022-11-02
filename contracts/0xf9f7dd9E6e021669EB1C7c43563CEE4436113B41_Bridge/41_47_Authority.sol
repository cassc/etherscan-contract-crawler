//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./Getters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title Authority
/// @notice This is a base contract to be used by other contracts which provide functionality based on messages
/// signed by the authority. Furthermore it allows off-chain entities which are willing to send messages to the bridge
/// to verify whether the message is correct.
/// @author Piotr "pibu" Buda
contract Authority is Getters {
    event AuthoritiesChanged(address[] newAuthorities);

    /// @notice verifies whether a message was signed by the quorum of current authorities
    /// @param message the message to verify
    /// @param digest the hash of the message content
    /// @return result the boolean result of the verification operation
    /// @return failureReason the description of an error if result is false, or an empty string if result is true
    function verifyMessage(Structs.VSM memory message, bytes32 digest) public view returns (bool result, string memory failureReason) {
        //because of the way the bridge is going to work, this contract will receive messages only from a specific chainId
        if (message.chainId != hubChainId()) {
            return (false, "IMPROPER_ORIGIN");
        }
        uint256 authorityLength = authoritiesLength();
        if (!quorum(message.signatures.length, authorityLength)) {
            return (false, "NO_QUORUM");
        }

        uint256 lastIndex = 0;

        for (uint256 i = 0; i < message.signatures.length; i++) {
            Structs.Signature memory signature = message.signatures[i];
            //on first iteration we assume the order is correct
            //on subsequent iterations the signature index must be
            require(i == 0 || signature.index > lastIndex, "INVALID_SIGNER_ORDER");
            lastIndex = signature.index;
            require(signature.index < authorityLength, "SIGNER_INDEX_OUT_OF_BOUNDS");
            (address authority, ECDSA.RecoverError error) = ECDSA.tryRecover(digest, signature.v, signature.r, signature.s);
            if (error != ECDSA.RecoverError.NoError || authority != getAuthority(signature.index)) {
                return (false, "INVALID_SIGNATURE");
            }
        }
        return (true, "");
    }

    /// @notice this method is used to check if some number of signatures are enough to reach quorum
    /// thus marking the message as clear for verification
    /// @param sigLength the actual number of signatures
    /// @param allKeys the number of keys in the authority
    function quorum(uint256 sigLength, uint256 allKeys) private pure returns (bool) {
        return sigLength >= (allKeys * 2) / 3 + 1;
    }
}