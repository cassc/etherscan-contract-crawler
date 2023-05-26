// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library SignatureVerification {
    using ECDSA for bytes32;

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol
    // https://docs.soliditylang.org/en/v0.8.4/solidity-by-example.html?highlight=ecrecover#the-full-contract

    /**
     * @dev Performs address recovery on data and signature. Compares recovred address to varification address.
     * @param data Packed data used for signature generation
     * @param signature Signature for the provided data
     * @param verificationAddress Address to compare to recovered address
     */
    function requireValidSignature(
        bytes memory data,
        bytes memory signature,
        address verificationAddress
    ) internal pure {
        require(
            verificationAddress != address(0),
            "verification address not initialized"
        );

        require(
            keccak256(data).toEthSignedMessageHash().recover(signature) ==
                verificationAddress,
            "signature invalid"
        );
    }
}