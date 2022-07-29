// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Treasury.sol";

import "hardhat/console.sol";

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
contract MerkleProof is Treasury {
    using ECDSA for bytes32;

    // ECDSA signing address
    address public signingAddress;

    /**
     * @dev To decrypt ECDSA sigs or invalidate signed but not claimed tokens
     */
    function setSigningAddress(address newSigningAddress) public onlyAdmin {
        if (newSigningAddress == address(0)) revert CannotSetZeroAddress();
        signingAddress = newSigningAddress;
    }

    /**
     * @dev Verify the ECDSA signature
     */
    function verifySig(address sender, bytes memory signature)
        internal
        view
        returns (bool)
    {
        // bytes32 messageHash = keccak256(
        //     abi.encodePacked(sender, maxMintable, valueSent)
        // );

        return
            signingAddress ==
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    bytes32(uint256(uint160(sender)))
                )
            ).recover(signature);
    }
}