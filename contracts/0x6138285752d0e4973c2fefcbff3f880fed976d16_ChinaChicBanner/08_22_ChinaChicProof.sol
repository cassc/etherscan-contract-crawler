// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// File: contracts/ChinaChicClaim.sol

/*
 ██████╗██╗  ██╗██╗███╗   ██╗ █████╗      ██████╗██╗  ██╗██╗ ██████╗
██╔════╝██║  ██║██║████╗  ██║██╔══██╗    ██╔════╝██║  ██║██║██╔════╝
██║     ███████║██║██╔██╗ ██║███████║    ██║     ███████║██║██║     
██║     ██╔══██║██║██║╚██╗██║██╔══██║    ██║     ██╔══██║██║██║     
╚██████╗██║  ██║██║██║ ╚████║██║  ██║    ╚██████╗██║  ██║██║╚██████╗
 ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝     ╚═════╝╚═╝  ╚═╝╚═╝ ╚═════╝
*/

/**
 * @title ChinaChic Proof utility contract
 * @dev Utility Contract made by China Chic DAO
 */
abstract contract ChinaChicProof is Ownable {
    using ECDSA for bytes32;

    // Constant variables
    // ------------------------------------------------------------------------

    // State variables
    // ------------------------------------------------------------------------
    address public verifier;

    // Sale mappings and array
    // ------------------------------------------------------------------------
    mapping(string => bool) private nonces;

    // Modifiers
    // ------------------------------------------------------------------------
    modifier onlyEOA() {
        require(tx.origin == msg.sender, "Must be externally owned account");
        _;
    }

    // Operational functions
    // ------------------------------------------------------------------------
    function setVerifier(address _verifier) external onlyOwner {
        verifier = _verifier;
    }

    function concat(uint256[] calldata tokenIds)
        public
        pure
        returns (string memory)
    {
        string memory output;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (bytes(output).length == 0) {
                output = Strings.toString(tokenIds[i]);
            } else {
                output = string(
                    abi.encodePacked(output, "-", Strings.toString(tokenIds[i]))
                );
            }
        }

        return output;
    }

    // Verify Signature functions
    // ------------------------------------------------------------------------
    function matchSigner(bytes32 hash, bytes memory signature)
        public
        view
        returns (bool)
    {
        return verifier == hash.toEthSignedMessageHash().recover(signature);
    }

    function hashMessage(
        address sender,
        string memory nonce,
        string memory ids
    ) public view returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(sender, nonce, ids, verifier)
        );
        return hash;
    }
}