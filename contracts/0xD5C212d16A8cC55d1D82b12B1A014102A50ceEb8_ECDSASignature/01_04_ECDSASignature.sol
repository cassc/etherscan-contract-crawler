// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IECDSASignature.sol";
contract ECDSASignature is IECDSASignature {
    using ECDSA for bytes32;
    uint256 constant _timePeriodInSeconds = 600; //10 minutes
    
    address[] private signers;
    
    event SignatureClaimed(
        bytes32 indexed claimHash,
        bytes32 indexed markedHash,
        uint256 nonce, 
        uint256 timestamp, 
        uint256 blockTimestamp, 
        bytes[] indexed signatures
    );

    mapping (uint256 => bool) internal nonceUsed;

    constructor(address[] memory _signers) {
        require(_signers.length >= 2, "A minimum of 2 signatories are required");

        signers.push(msg.sender);

        for (uint i = 0; i < _signers.length; i++) {
            signers.push(_signers[i]);
        }
    }

    function _verify(bytes32 data, bytes memory signature, address account) private pure returns (bool) {
        return data
        .toEthSignedMessageHash()   
        .recover(signature) == account;
    }
 
    function watermark(bytes32 message, uint256 timestamp, uint256 nonce) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(message, timestamp, nonce));
    }

    /// @dev Verify that the amount of bars to receive by the player is correct
    /// @param signatures Signatures created by each of the signatories
    function verifyMessage(bytes32 messageHash, uint256 nonce, uint256 timestamp, bytes[] memory signatures) external {
        bytes32 markedHash = watermark(messageHash, timestamp, nonce);
        bool result = verifyByTheSigners(markedHash, signatures);

        require(result, "hash or signature is invalid");
        require(nonceUsed[nonce] == false, "nonce was already used");
        require(block.timestamp <= timestamp, "this signature is not valid, its lifetime has expired");
        nonceUsed[nonce] = true;
        emit SignatureClaimed(messageHash, markedHash, nonce, timestamp, block.timestamp, signatures);
    }

    /// @dev Check the status of a claim signature
    /// @param messageHash hash
    /// @param signatures Signatures created by each of the signatories
    /// @return uint8: 1 = hash or signature is invalid, 2 = nonce was already used, 3 = lifetime has expired, 0 = Ok - Success
    function signatureStatus(bytes32 messageHash, uint256 nonce, uint256 timestamp, bytes[] memory signatures) external view returns(uint8){
        bool result = verifyByTheSigners(watermark(messageHash, timestamp, nonce), signatures);
        if(!result) return 1;
        if(nonceUsed[nonce]) return 2;
        if(block.timestamp > timestamp) return 3;
        return 0;
    }

    function verifyByTheSigners(bytes32 markedHash, bytes[] memory signatures) private view returns (bool) {
        if(signatures.length < signers.length) revert("Signatures are missing");
        if(signatures.length > signers.length) revert("Too many signatures");
        
        uint validSignatures = 0;
        uint validSigners = signers.length * 1e4;

        for (uint i = 0; i < signers.length; i++) {
            address signer = signers[i];

            for(uint j = 0; j < signatures.length; j++) {
                bytes memory signature = signatures[j];
                bool result = _verify(markedHash, signature, signer);

                if(result) validSignatures = validSignatures + (1 * 1e4);
                if(validSignatures > (validSigners / 2)) return true;
            }
        }

        return false;
    }

    function checkNonce(uint256 nonce) external view returns (bool) {
        return nonceUsed[nonce];
    }
}