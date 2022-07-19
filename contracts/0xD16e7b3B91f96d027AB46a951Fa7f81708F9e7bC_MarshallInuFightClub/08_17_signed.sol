// SPDX-License-Identifier: BSD-3

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Signed is Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    string private _secret;
    address private _signer;

    function setSecret(string calldata secret) external onlyOwner {
        _secret = secret;
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
    }

    function createHash() internal view returns (bytes32) {
        return keccak256(abi.encode(address(this), msg.sender, _secret));
    }

    function getSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(signature);
    }

    function isAuthorizedSigner(address extracted)
        internal
        view
        virtual
        returns (bool)
    {
        return extracted == _signer;
    }

    function verifySignature(bytes calldata signature) internal view {
        address extracted = getSigner(createHash(), signature);
        require(isAuthorizedSigner(extracted), "Signature verification failed");
    }

    function createHash(bool _isVIP) internal view returns (bytes32) {
        return
            keccak256(abi.encode(address(this), msg.sender, _secret, _isVIP));
    }

    function verifySignatureVIP(bytes calldata signature, bool isVIP)
        internal
        view
    {
        address extracted = getSigner(createHash(isVIP), signature);
        require(isAuthorizedSigner(extracted), "Signature verification failed");
    }
}