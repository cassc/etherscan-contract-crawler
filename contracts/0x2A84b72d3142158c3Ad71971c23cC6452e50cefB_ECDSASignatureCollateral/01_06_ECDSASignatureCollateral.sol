// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../ECDSASignatureBase.sol";
import "../interfaces/IECDSASignatureCollateral.sol";

contract ECDSASignatureCollateral is ECDSASignatureBase, IECDSASignatureCollateral {
    using ECDSA for bytes32;
   
    constructor(address signature) ECDSASignatureBase(signature) {}
    
    function hashingExtractMessage(address to, uint256 amount) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(to, amount));
    }

    function hashingSetCollateralMessage(address tokenAddress) external pure returns (bytes32){
        return keccak256(abi.encodePacked(tokenAddress));
    }
    
    /// @param signatures Signatures created by each of the signatories
    function verifyMessage(bytes32 messageHash, uint256 nonce, uint256 timestamp, bytes[] memory signatures) external {
       signature.verifyMessage(messageHash, nonce, timestamp, signatures);
    }
}