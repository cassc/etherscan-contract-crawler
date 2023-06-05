// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISignatureManager {
    function verify(
        address owner,
        uint256 tokenId,
        string memory uri,
        uint8 phase,
        bytes memory signature
    ) external returns (bool);

}