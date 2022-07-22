// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SigVer {
    using ECDSA for bytes32;

    function verifyMsg(
        address sender, 
        uint256 value,
        bytes32 msgHash,  
        bytes memory signature,
        address _signer
    ) public pure returns (bool) {
        return _verifyMsg(sender, value, msgHash, signature, _signer);
    }

    function hashMsg(
        address sender,
        uint256 value
    ) public pure returns (bytes32) {
        return _hashMsg(sender, value);
    }

    function verifySigner(
        bytes32 msgHash,
        bytes memory signature,
        address _signer
    ) public pure returns (bool) {
        return _verifySigner(msgHash, signature, _signer);
    }
    
    function _verifyMsg(
        address sender, 
        uint256 value,
        bytes32 msgHash,  
        bytes memory signature,
        address _signer
    ) internal pure returns (bool) {
        return (
            _verifySigner(msgHash, signature, _signer) 
            && _hashMsg(sender, value) == msgHash
        );
    }

    function _hashMsg(
        address sender, 
        uint256 value
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender, value));
    }

    function _verifySigner(
        bytes32 msgHash, 
        bytes memory signature,
        address _signer
    ) internal pure returns (bool) {
        return msgHash.toEthSignedMessageHash().recover(signature) == _signer;
    }
}