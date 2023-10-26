// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./NiftyPermissions.sol";
import "../libraries/ECDSA.sol";
import "../structs/SignatureStatus.sol";

abstract contract Signable is NiftyPermissions {        

    event ContractSigned(address signer, bytes32 data, bytes signature);

    SignatureStatus public signatureStatus;
    bytes public signature;

    string internal constant ERROR_CONTRACT_ALREADY_SIGNED = "Contract already signed";
    string internal constant ERROR_CONTRACT_NOT_SALTED = "Contract not salted";
    string internal constant ERROR_INCORRECT_SECRET_SALT = "Incorrect secret salt";
    string internal constant ERROR_SALTED_HASH_SET_TO_ZERO = "Salted hash set to zero";
    string internal constant ERROR_SIGNER_SET_TO_ZERO = "Signer set to zero address";

    function setSigner(address signer_, bytes32 saltedHash_) external {
        _requireOnlyValidSender();

        require(signer_ != address(0), ERROR_SIGNER_SET_TO_ZERO);
        require(saltedHash_ != bytes32(0), ERROR_SALTED_HASH_SET_TO_ZERO);
        require(!signatureStatus.isVerified, ERROR_CONTRACT_ALREADY_SIGNED);
        
        signatureStatus.signer = signer_;
        signatureStatus.saltedHash = saltedHash_;
        signatureStatus.isSalted = true;
    }

    function sign(uint256 salt, bytes calldata signature_) external {
        require(!signatureStatus.isVerified, ERROR_CONTRACT_ALREADY_SIGNED);        
        require(signatureStatus.isSalted, ERROR_CONTRACT_NOT_SALTED);
        
        address expectedSigner = signatureStatus.signer;
        bytes32 expectedSaltedHash = signatureStatus.saltedHash;

        require(_msgSender() == expectedSigner, ERROR_INVALID_MSG_SENDER);
        require(keccak256(abi.encodePacked(salt)) == expectedSaltedHash, ERROR_INCORRECT_SECRET_SALT);
        require(ECDSA.recover(ECDSA.toEthSignedMessageHash(expectedSaltedHash), signature_) == expectedSigner, ERROR_UNEXPECTED_DATA_SIGNER);
        
        signature = signature_;        
        signatureStatus.isVerified = true;

        emit ContractSigned(expectedSigner, expectedSaltedHash, signature_);
    }
}