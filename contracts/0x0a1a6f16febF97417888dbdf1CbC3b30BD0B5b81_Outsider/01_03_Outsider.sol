// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Outsider {
    using ECDSA for bytes32;

    event ProofOfEOA(address indexed subject);

    /// @dev Using this seems to be around 1500 gas more expensive than recovering an address.
    mapping(address => bool) public isEOA;

    /// @notice Gas savings
    bytes32 constant private messageHash = 0xe171a8671c07fc3c8903fd80085d685735c5343be5eb544bec23614c63e0dc3a;
    // =
    /*
    / bytes32 messageHash = keccak256(
    /     abi.encodePacked(
    /         "I am worthy."
    /     )
    / );
    */

    /// @notice Proof being an EOA once, then remember that on chain
    /// @dev Uses openzeppelin ECDSA.sol to increase the security of this implementation
    function proofEOA(address _subject, bytes memory _sig) external {
        // ECDSA recovery
        address signer = messageHash.toEthSignedMessageHash().recover(_sig);

        require(signer == _subject, "Invalid proof...");

        emit ProofOfEOA(signer);
        isEOA[signer] = true;
    }
}