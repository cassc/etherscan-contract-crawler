// SPDX-License-Identifier: BSD-3

pragma solidity ^0.8.0;

import "./Delegated.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol";

contract Signed is Delegated {
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

    function createHash(string memory data) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), msg.sender, data, _secret));
    }

    function getSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        return hash.toEthSignedMessageHash().recover(signature);
    }

    function isAuthorizedSigner(address extracted) internal view virtual returns (bool) {
        return extracted == _signer;
    }

    function verifySignature(string memory data, bytes calldata signature) internal view {
        address extracted = getSigner(createHash(data), signature);
        require(isAuthorizedSigner(extracted), "Signature verification failed");
    }
}