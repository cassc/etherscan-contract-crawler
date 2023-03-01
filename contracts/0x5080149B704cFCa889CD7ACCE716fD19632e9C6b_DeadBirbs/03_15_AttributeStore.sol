// SPDX-License-Identifier: MIT
// Creator: deadbirbs.xyz

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AttributeStore is Ownable {
    using ECDSA for bytes32;

    address public attributeSigner;

    mapping(string => address) public firstMinters;
    mapping(uint256 => string) public tokenAttributes;

    function setAttributeSigner(address signer) public onlyOwner {
        attributeSigner = signer;
    }

    function verifyAttributes(string memory attributes, bytes memory signature) internal virtual view {
        checkSignature(attributeSigner, attributes, signature);
        require(firstMinters[attributes] == address(0), "hash has been minted already");
    }

    function checkSignature(address signer, string memory attributes, bytes memory signature) private pure {
        bytes32 messageHash = keccak256(abi.encodePacked(attributes));
        require(signer == messageHash.toEthSignedMessageHash().recover(signature), string(abi.encodePacked(messageHash)));
    }

    function storeAttributes(string memory attributes, address minter, uint256 tokenId) internal {
        firstMinters[attributes] = minter;
        tokenAttributes[tokenId] = attributes;
    }
}