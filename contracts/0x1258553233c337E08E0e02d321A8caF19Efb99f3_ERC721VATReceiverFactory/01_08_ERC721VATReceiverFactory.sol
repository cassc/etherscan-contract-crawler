// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721VATReceiver.sol";

contract ERC721VATReceiverFactory {
    function createReceiver(address nft, uint256 nonce) public {
        bytes32 salt = keccak256(abi.encodePacked(nft, nonce));
        ERC721VATReceiver x = new ERC721VATReceiver{ salt: salt }(nft);
        x.transferOwnership(msg.sender);
    }

    function calculateReceiver(address nft, uint256 nonce) public view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(nft, nonce));
        bytes memory bytecode = abi.encodePacked(type(ERC721VATReceiver).creationCode, abi.encode(nft));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));
        return address(uint160(uint256(hash)));
    }
}