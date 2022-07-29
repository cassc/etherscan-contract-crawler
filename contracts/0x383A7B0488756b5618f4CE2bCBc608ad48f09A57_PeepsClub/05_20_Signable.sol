// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title Signable
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// https://block.aocollab.tech
/// Check signed messages.

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Signable is Ownable {
    using ECDSA for bytes32;

    address public signer;

    /**
     * Checks if the signature matches data signed by the signer.
     * @param data The data to sign.
     * @param signature The expected signed data.
     */
    modifier signed(bytes memory data, bytes memory signature) {
        require(_verify(data, signature, signer), "PeepsPassport: Signature not valid");
        _;
    }

    /**
     * Update the utility signer.
     * @param _signer The new utility signing address.
     */
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /**
     * Verify a signature.
     * @param data The signature data.
     * @param signature The signature to verify.
     * @param account The signer account.
     */
    function _verify(
        bytes memory data,
        bytes memory signature,
        address account
    ) public pure returns (bool) {
        return keccak256(data).toEthSignedMessageHash().recover(signature) == account;
    }
}